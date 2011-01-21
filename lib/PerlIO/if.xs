#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

int is_buffered(pTHX_ PerlIO* f) {
	if (PerlIOValid(f)) {
		PerlIO* t = f;
		const PerlIOl* l;
		while (t && (l = *t)) {
			if (l->tab && l->tab->kind & PERLIO_K_BUFFERED && !(l->flags & PERLIO_F_UNBUF))
				return 1;
			t = PerlIONext(t);
		}
	}
	return 0;
}

int is_crlf(pTHX_ PerlIO* f) {
	if (PerlIOValid(f)) {
		PerlIO* t = f;
		const PerlIOl* l;
		while (t && (l = *t)) {
			if (l->tab && l->tab->kind & PERLIO_K_CANCRLF && l->flags & PERLIO_F_CRLF)
				return 1;
			t = PerlIONext(t);
		}
	}
	return 0;
}

int can_crlf(pTHX_ PerlIO* f) {
	if (PerlIOValid(f)) {
		PerlIO* t = f;
		const PerlIOl* l;
		while (t && (l = *t)) {
			if (l->tab && l->tab->kind & PERLIO_K_CANCRLF)
				return 1;
			t = PerlIONext(t);
		}
	}
	return 0;
}

typedef int (*func)(pTHX_ PerlIO*);
typedef struct { const char* key; func value; } map;

static map tests[] = {
	{ "buffered", is_buffered },
	{ "crlf"    , is_crlf     },
	{ "can_crlf" , can_crlf    },
};

static func S_get_io_test(pTHX_ const char* test_name) {
	int i;
	for (i = 0; i < sizeof tests / sizeof *tests; ++i) {
		if (strEQ(test_name, tests[i].key))
			return tests[i].value;
	}
	Perl_croak(aTHX_ "No such test '%s' known", test_name);
}
#define get_io_test(name) S_get_io_test(aTHX_ name)

static IV PerlIOIf_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab) {
	if (PerlIOValid(f) && SvOK(arg)) {
		SV* test_name;
		const char* layer;
		int negate;
		func test;
		const char* argstr = SvPV_nolen(arg);
		const char* delim = strchr(argstr, ',');

		if (!delim)
			Perl_croak(aTHX_ "No layer specified in :if(%s)!", argstr);
		negate = argstr[0] == '!';
		if (negate)
			argstr++;
		test_name = sv_2mortal(newSVpvn(argstr, delim - argstr));
		layer = delim + 1;
		while(isblank(*layer))
			layer++;
		test = get_io_test(SvPV_nolen(test_name));
		if (test(aTHX_ f) != negate)
			PerlIO_apply_layers(aTHX_ f, mode, layer);
		return 0;
	}
	return -1;
}

PerlIO_funcs PerlIO_if = {
	sizeof(PerlIO_funcs),
	"if",
	0,
	PERLIO_K_DUMMY | PERLIO_K_UTF8 | PERLIO_K_MULTIARG,
	PerlIOIf_pushed,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,                       /* flush */
	NULL,                       /* fill */
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,                       /* get_base */
	NULL,                       /* get_bufsiz */
	NULL,                       /* get_ptr */
	NULL,                       /* get_cnt */
	NULL,                       /* set_ptrcnt */
};


MODULE = PerlIO::if				PACKAGE = PerlIO::if

BOOT:
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_if));
