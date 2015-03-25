/*
 * toast_hybrid.c
 *
 * Modified toast.c for using in MiBenchHybrid
 *
 * Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
 * 
 * History:	08.03.2013 Alexander Sprenger created
 * 
 * */

/*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 */

/*RECONOS HEADERFILES*/
#include "reconos.h"
#include "rqueue.h"

#ifdef SHADOWING
#include "thread_shadowing.h"
#include "thread_shadowing_subs.h"
#endif

/* MiBenchHybrid */
#include "mibench_hybrid.h"

#include "timing.h"

#include "thread_helpers.h"
#include "slot_map.h"

#include <stdint.h>
#include <stdio.h>
#include <limits.h>
#include <pthread.h>
#include <sys/stat.h>


//Length of Reconosqueues
#define INDATA_LEN 5
#define OUTDATA_LEN 1

//undefine to see more details on stderr
#define _MIBENCHOUTPUT

//define to see on opertational time on stderr
#define _PRINT_TIMES

/* $Header: /home/mguthaus/.cvsroot/mibench/telecomm/gsm/src/toast.c,v 1.1.1.1 2000/11/06 19:54:26 mguthaus Exp $ */
#include "toast.h"
#include <fcntl.h> //bug fix: fcntl.h should be included in toast.h

/*  toast -- lossy sound compression using the gsm library.
 */

char   * progname;

int	f_decode   = 0;		/* decode rather than encode	 (-d) */
int f_cat	   = 0;		/* write to stdout, not foo.gsm	 (-c) */
int	f_force	   = 0;		/* force deletion 		 (-f) */
int	f_precious = 0;		/* avoid deletion		 (-p) */
int	f_fast	   = 0;		/* use faster fpt algorithm	 (-F) */
int	f_verbose  = 0;		/* debugging			 (-V) */

/*
 * RECONOS STUFF START
 */
/*MiBenchHybrid*/
int f_hybrid   = 0;		/* Hybrid variant (-H)*/
int f_transmodal = 0;   /* Not yet implemented, no commandline option specified*/
int sw_threads = 0;		/* Number of Softwarethreads */
int hw_threads = 0;		/* Number of Hardwarethreads */
//ReconOSqueues
rqueue rq_SENDING;
rqueue rq_RECIEVE;

struct reconos_resource res[2];


#ifdef SHADOWING
// Thread shadowing

int f_shadowing = 0; /* Flag set from commandline, (de-)activates shadowing */

shadowedthread_t sh[MAX_THREADS];
unsigned int sh_free_idx=0;
#else
// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_hwt hwt[MAX_THREADS];

// workercpu threads
struct reconos_hwt hwt_worker[MAX_THREADS];
#endif

/*
 * RECONOS STUFF STOP
 */

struct stat instat;		/* stat (inname) 		 */

FILE	*in, 	 *out;
char	*inname, *outname;

/*
 *  The function (*output)() writes a frame of 160 samples given as
 *  160 signed 16 bit values (gsm_signals) to <out>.
 *  The function (*input)() reads one such frame from <in>.
 *  The function (*init_output)() begins output (e.g. writes a header).,
 *  The function (*init_input)() begins input (e.g. skips a header).
 *
 *  There are different versions of input, output, init_input and init_output
 *  for different formats understood by toast; which ones are used 
 *  depends on the command line arguments and, in their absence, the
 *  filename; the fallback is #defined in toast.h
 *
 *  The specific implementations of input, output, init_input and init_output
 *  for a format `foo' live in toast_foo.c.
 */

int	(*output   ) P((gsm_signal *)),
	(*input    ) P((gsm_signal *));
int	(*init_input)  P((void)),
	(*init_output) P((void));
	
//Softwarethread deklaration
extern void *short_term_synthesis_filtering_swt(void* data);

/* 
 * string_is_number
 * controlls if the given string is a number
 * returns 1 if true; else 0
 */
int string_is_number(char const *str)
{
	while(*str)
	{
		if(!isdigit(*str))
		{
				return 0;
		}
		str++;
	}
	return 1;
}	//added by A.

static int	generic_init P0() { return 0; }	/* NOP */

struct fmtdesc {

	char * name, * longname, * suffix;

	int  (* init_input )  P((void)),
	     (* init_output)  P((void));

	int  (* input ) P((gsm_signal * )),
	     (* output) P((gsm_signal * ));

} f_audio = {
		"audio",
		"8 kHz, 8 bit u-law encoding with Sun audio header", ".au",
		audio_init_input,
		audio_init_output,
		ulaw_input,
		ulaw_output
}, f_ulaw = {
		"u-law", "plain 8 kHz, 8 bit u-law encoding", ".u",
		generic_init,
		generic_init,
		ulaw_input,
		ulaw_output 

}, f_alaw = {
		"A-law", "8 kHz, 8 bit A-law encoding", ".A",
		generic_init,
		generic_init,
		alaw_input,
		alaw_output

}, f_linear = {
		"linear",
		"16 bit (13 significant) signed 8 kHz signal", ".l",
		generic_init,
		generic_init,
		linear_input,
		linear_output
};

struct fmtdesc * alldescs[] = {
	&f_audio,
	&f_alaw,
	&f_ulaw,
	&f_linear,
	(struct fmtdesc *)NULL
};

#define	DEFAULT_FORMAT	f_ulaw		/* default audio format, others	*/
					/* are: f_alaw,f_audio,f_linear */
struct fmtdesc * f_format  = 0;

/*
 *  basename + suffix of a pathname
 */
static char * endname P1((name), char * name)
{
	if (name) {
		char * s = strrchr(name, '/');
		if (s && s[1]) name = s + 1;
	}
	return name;

}

/*
 *  Try to figure out what we're supposed to do from the argv[0], if
 *  any, and set the parameters accordingly.
 */
static void parse_argv0 P1((av0), char * av0 )
{
	int 	l;

	progname = av0 = endname(av0 ? av0 : "toast_hybrid");

	/*  If the name starts with `un', we want to decode, not code.
	 *  If the name ends in `cat', we want to write to stdout,
	 *  and decode as well.
	 */

	if (!strncmp(av0, "un", 2)) f_decode = 1;
	if (  (l = strlen(av0)) >= 3 /* strlen("cat") */
	   && !strcmp( av0 + l - 3, "cat" )) f_cat = f_decode = 1;
}


/*
 *  Check whether the name (possibly generated by appending
 *  .gsm to something else) is short enough for this system.
 */
static int length_okay P1((name), char * name)
{
	long	max_filename_length = 0;
	char	* end;

	/* If our _pathname_ is too long, we'll usually not be
	 * able to open the file at all -- don't worry about that.
	 * 
	 * But if the _filename_ is too long, there is danger of
	 * silent truncation on some systems, which results
	 * in the target replacing the source!
	 */

	if (!name) return 0;
	end = endname(name);

#ifdef	NAME_MAX
	max_filename_length  = NAME_MAX;
#else
#ifdef	_PC_NAME_MAX
#ifdef USE_PATHCONF
	{	char * s, tmp; 
		
		/*  s = dirname(name)
		 */
		if ((s = end) > name) {
			if (s > name + 1) s--;
			tmp = s;
			*s  = 0;
		}

		errno = 0;
		max_filename_length = pathconf(s > name ? name : ".",
			_PC_NAME_MAX);
		if (max_filename_length == -1 && errno) {
			perror( s > name ? name : "." );
			fprintf(stderr,
		"%s: cannot get dynamic filename length limit for %s.\n",
				progname, s > name ? name : ".");
			return 0;
		}
		if (s > name) *s = tmp;
	}
#endif /* USE_PATHCONF  */
#endif /* _PC_NAME_MAX  */
#endif /* !NAME_MAX 	*/

	if (max_filename_length > 0 && strlen(end) > max_filename_length) {
		fprintf(stderr,
			"%s: filename \"%s\" is too long (maximum is %ld)\n",
			progname, endname(name), max_filename_length );
		return 0;
	}

	return 1;
}

/*
 *  Return a pointer the suffix of a string, if any.
 *  A suffix alone has no suffix, an empty suffix can not be had.
 */
static char * suffix P2((name, suf), char *name, char * suf) 
{
	size_t nlen = strlen(name);
	size_t slen = strlen(suf);

	if (!slen || nlen <= slen) return (char *)0;
	name += nlen - slen;
	return memcmp(name, suf, slen) ? (char *)0 : name;
}


static void catch_signals P1((fun), SIGHANDLER_T (*fun) ()) 
{
#ifdef	SIGHUP
	signal( SIGHUP,   fun );
#endif
#ifdef	SIGINT
	signal( SIGINT,   fun );
#endif
#ifdef	SIGPIPE
	signal( SIGPIPE,  fun );
#endif
#ifdef	SIGTERM
	signal( SIGTERM,  fun );
#endif
#ifdef	SIGXFSZ
	signal( SIGXFSZ,  fun );
#endif
}

static SIGHANDLER_T onintr P0()
{
	char * tmp = outname;

#ifdef	HAS_SYSV_SIGNALS
	catch_signals( SIG_IGN );
#endif

	outname = (char *)0;
	if (tmp) (void)unlink(tmp);

	exit(1);
}

/*
 *  Allocate some memory and complain if it fails.
 */
static char * emalloc P1((len), size_t len)
{
	char * s;
	if (!(s = malloc(len))) {
		fprintf(stderr, "%s: failed to malloc %d bytes -- abort\n",
			progname, len);
		onintr();
		exit(1);
	}
	return s;
}

static char* normalname P3((name, want, cut), char *name, char *want,char *cut)
{
	size_t	maxlen;
	char 	* s, * p;

	p = (char *)0;
	if (!name) return p;

	maxlen = strlen(name) + 1 + strlen(want) + strlen(cut);
	p = strcpy(emalloc(maxlen), name);

	if (s = suffix(p, cut)) strcpy(s, want);
	else if (*want && !suffix(p, want)) strcat(p, want);

	return p;
}

/*
 *  Generate a `plain' (non-encoded) name from a given name.
 */
static char * plainname P1((name), char *name)
{
	return normalname(name, "", SUFFIX_TOASTED );
}

/*
 *  Generate a `code' name (foo.Z) from a given name.
 */
static char * codename P1((name), char *name)
{
	return normalname( name, SUFFIX_TOASTED, "" );
}

/*
 *  If we're supposed to ask (fileno (stderr) is a tty, and f_force not
 *  set), ask the user whether to overwrite a file or not.
 */
static int ok_to_replace P1(( name ), char * name)
{
	int reply, c;

	if (f_force) return 1;			/* YES, do replace   */
	if (!isatty(fileno(stderr))) return 0;	/* NO, don't replace */

	fprintf(stderr,
		"%s already exists; do you wish to overwrite %s (y or n)? ",
		name, name);
	fflush(stderr);

	for (c = reply = getchar(); c != '\n' && c != EOF; c = getchar()) ;
	if (reply == 'y') return 1;

	fprintf(stderr, "\tnot overwritten\n");
	return 0;
}

static void update_mode P0()
{
	if (!instat.st_nlink) return;		/* couldn't stat in */

#ifdef HAS_FCHMOD
	if (fchmod(fileno(out), instat.st_mode & 07777)) {
		perror(outname);
		fprintf(stderr, "%s: could not change file mode of \"%s\"\n",
			progname, outname);
	}
#else 
	if (outname && chmod(outname, instat.st_mode & 07777)) {
		perror(outname);
		fprintf(stderr, "%s: could not change file mode of \"%s\"\n",
			progname, outname);
	}
#endif /* HAS_FCHMOD */
}

static void update_own P0()
{
	if (!instat.st_nlink) return; /* couldn't stat in */
#ifdef HAS_FCHOWN
	(void)fchown(fileno(out), instat.st_uid, instat.st_gid);
#else 
	(void)chown(outname, instat.st_uid, instat.st_gid);
#endif /* HAS_FCHOWN */
}

static void update_times P0()
{
	if (!instat.st_nlink) return; 	/* couldn't stat in */

#ifdef HAS_UTIMES
	if (outname) {
		struct timeval tv[2];

		tv[0].tv_sec  = instat.st_atime;
		tv[1].tv_sec  = instat.st_mtime;
		tv[0].tv_usec = tv[1].tv_usec = 0;
		(void) utimes(outname, tv);
	}
#else
#ifdef HAS_UTIME

	if (outname) {

#ifdef	HAS_UTIMBUF
		struct utimbuf ut;

		ut.actime     = instat.st_atime;
		ut.modtime    = instat.st_mtime;

#	ifdef	HAS_UTIMEUSEC
		ut.acusec     = instat.st_ausec;
		ut.modusec    = instat.st_musec;
#	endif 	/* HAS_UTIMEUSEC */

		(void) utime(outname, &ut);

#else /* UTIMBUF */

		time_t ut[2];

		ut[0] = instat.st_atime;
		ut[1] = instat.st_mtime;

		(void) utime(outname, ut);

#endif	/* UTIMBUF */
	}
#endif /* HAS_UTIME */
#endif /* HAS_UTIMES */
}


static int okay_as_input P3((name,f,st), char* name, FILE* f, struct stat * st)
{
# ifdef	HAS_FSTAT
	if (fstat(fileno(f), st) < 0)
# else
	if (stat(name, st) < 0)
# endif
	{
		perror(name);
		fprintf(stderr, "%s: cannot stat \"%s\"\n", progname, name);
		return 0;
	}

	if (!S_ISREG(st->st_mode)) {
		fprintf(stderr,
			"%s: \"%s\" is not a regular file -- unchanged.\n",
			progname, name);
		return 0;
	}
	if (st->st_nlink > 1 && !f_cat && !f_precious) {
		fprintf(stderr, 
		      "%s: \"%s\" has %s other link%s -- unchanged.\n",
			progname,name,st->st_nlink - 1,"s" + (st->st_nlink<=2));
		return 0;
	}
	return 1;
}

static void prepare_io P1(( desc), struct fmtdesc * desc)
{
	output      = desc->output;
	input       = desc->input;

	init_input  = desc->init_input;
	init_output = desc->init_output;
}

static struct fmtdesc * grok_format P1((name), char * name)
{
	char * c;
	struct fmtdesc ** f;

	if (name) {
		c = plainname(name);

		for (f = alldescs; *f; f++)
			if (  (*f)->suffix
			   && *(*f)->suffix
			   && suffix(c, (*f)->suffix)) {

				free(c);
				return *f;
			}

		free(c);
	}
	return (struct fmtdesc *)0;
}

static int open_input P2((name, st), char * name, struct stat * st)
{
	struct fmtdesc * f = f_format;

	st->st_nlink = 0;	/* indicates `undefined' value */
	if (!name) {
		inname = (char *)NULL;
		in     = stdin;
	}
	else {
		if (f_decode) inname = codename(name);
		else {
			if (!f_cat && suffix(name, SUFFIX_TOASTED)) {
				fprintf(stderr,
			"%s: %s already has \"%s\" suffix -- unchanged.\n",
					progname, name, SUFFIX_TOASTED );
				return 0;
			}
			inname = strcpy(emalloc(strlen(name)+1), name);
		}
		if (!(in = fopen(inname, READ))) {
			perror(inname);	/* not guaranteed to be valid here */
			fprintf(stderr, "%s: cannot open \"%s\" for reading\n",
				progname, inname);
			return 0;
		}
		if (!okay_as_input(inname, in, st)) return 0;
		if (!f) f = grok_format(inname);
	}
	prepare_io( f ? f : & DEFAULT_FORMAT );
	return 1;
}

static int open_output P1((name), char *name)
{
	if (!name || f_cat) {
		out     = stdout;
		outname = (char *)NULL;
	}
	else {
		int outfd = -1;
		char * o;

		o = (*(f_decode ? plainname : codename))(name);
		if (!length_okay(o)) return 0;
		if ((outfd = open(o, O_WRITE_EXCL, 0666)) >= 0)
			out = fdopen(outfd, WRITE);
		else if (errno != EEXIST) out = (FILE *)NULL;
		else if (ok_to_replace(o)) out = fopen(o, WRITE);
		else return 0;

		if (!out) {
			perror(o);
			fprintf(stderr,
				"%s: can't open \"%s\" for writing\n",
				progname, o);
			if (outfd >= 0) (void)close(outfd);
			return 0;
		}

		outname = o;
	}
	return 1;
}

static int process_encode P0()
{
	gsm      	r;
	gsm_signal    	s[ 160 ];
	gsm_frame	d;
 
	int		cc;

	if (!(r = gsm_create())) {
		perror(progname);
		return -1;
	}
	(void)gsm_option(r, GSM_OPT_FAST,    &f_fast);
	(void)gsm_option(r, GSM_OPT_VERBOSE, &f_verbose);

	while ((cc = (*input)(s)) > 0) {
		if (cc < sizeof(s) / sizeof(*s))
			memset((char *)(s+cc), 0, sizeof(s)-(cc * sizeof(*s)));
		gsm_encode(r, s, d);
		if (fwrite((char *)d, sizeof(d), 1, out) != 1) {
			perror(outname ? outname : "stdout");
			fprintf(stderr, "%s: error writing to %s\n",
				progname, outname ? outname : "stdout");
			gsm_destroy(r);
			return -1;
		}
	}
	if (cc < 0) {
		perror(inname ? inname : "stdin");
		fprintf(stderr, "%s: error reading from %s\n",
			progname, inname ? inname : "stdin");
		gsm_destroy(r);
		return -1;
	}
	gsm_destroy(r);

	return 0;
}

static int process_decode P0()
{
	gsm      	r;
	gsm_frame	s;
	gsm_signal	d[ 160 ];
	
	int		cc;
	
	//Mibench Variables
	int i=0;
	unsigned int sh_free_idx=0;
	int running_threads = sw_threads + hw_threads;
	uint32 indata[INDATA_LEN];
	uint32 outdata[OUTDATA_LEN];
	
	//Timing
	timing_t t_start, t_stop;
	ms_t t_generate_threads = 0;
	ms_t t_terminate_threads = 0;
	ms_t t_gsm_decode = 0;
 
	/* MiBenchHybrid thread generation */
	t_start = gettime();
	/* reconos init*/
	rq_init(&rq_SENDING, 10);
	rq_init(&rq_RECIEVE, 10);
	  
	res[0].type = RECONOS_TYPE_RQ;
	res[0].ptr  = &rq_SENDING;
	res[1].type = RECONOS_TYPE_RQ;
	res[1].ptr  = &rq_RECIEVE;
	
	reconos_init_autodetect();
	
	/*
	 * Creating threads
	 * Some explanation of wording:
	 *   hw_thread -> functionality implemented in hw in a hw slot
	 *   sw_thread -> functionality implemented in sw on a CPU in a hw slot
	 *   mt_thread/host -> functionality implemented on systems main processor, which also runs this programm
	 */
#ifdef SHADOWING
	prepare_threads_shadowing(running_threads,
								res,
								2,
								sh,
								NULL,
								short_term_synthesis_filtering_swt,
								f_hybrid);
#ifndef HOST_COMPILE
	start_threads_shadowing_hw(hw_threads,
								sh,
								&sh_free_idx,
								actual_slot_map,
								"SLOT_GSM",
								f_shadowing,
								f_transmodal);

	start_threads_shadowing_sw(0,
								sh,
								&sh_free_idx,
								actual_slot_map,
								"SLOT_GSM_SW",
								f_shadowing,
								f_transmodal);
#endif // HOST_COMPILE
	start_threads_shadowing_host(sw_threads,
									sh,
									&sh_free_idx,
									actual_slot_map,
									"SLOT_GSM",
									f_shadowing,
									f_transmodal);
#else // not SHADOWING

#ifndef HOST_COMPILE
	start_threads_hw(hw_threads,
						res,
						2,
						hwt,
						"SLOT_GSM",
						actual_slot_map);

	start_threads_sw(0,
						res,
						2,
						hwt_worker,
						"SLOT_GSM_SW",
						actual_slot_map);
#endif // HOST_COMPILE
	start_threads_host(sw_threads,
						res,
						2,
						swt,
						swt_attr,
						short_term_synthesis_filtering_swt);
#endif // SHADOWING

	t_stop = gettime();
	t_generate_threads = calc_timediff_ms(t_start,t_stop);
	/* END: MiBenchHybrid thread generation*/

	if (!(r = gsm_create())) {	/* malloc failed */
		perror(progname);
		return -1;
	}
	(void)gsm_option(r, GSM_OPT_FAST,    &f_fast);
	(void)gsm_option(r, GSM_OPT_VERBOSE, &f_verbose);
	
	while ((cc = fread(s, 1, sizeof(s), in)) > 0) {

		if (cc != sizeof(s)) {
			if (cc >= 0) fprintf(stderr,
			"%s: incomplete frame (%d byte%s missing) from %s\n",
					progname, sizeof(s) - cc,
					"s" + (sizeof(s) - cc == 1),
					inname ? inname : "stdin" );
			gsm_destroy(r);
			errno = 0;
			return -1;
		}

		if(f_hybrid)
		{	
			/* MiBenchHybrid gsm_decode*/
			t_start = gettime();
			if (gsm_decode_hybrid(r, s, d, &rq_SENDING, &rq_RECIEVE)) {
				fprintf(stderr, "%s: bad frame in %s\n", 
					progname, inname ? inname : "stdin");
				gsm_destroy(r);
				errno = 0;
				return -1;
			}
			t_stop = gettime();
			t_gsm_decode += calc_timediff_ms(t_start,t_stop);
		}
		else
		{
			/* MiBench gsm_decode */
			t_start = gettime();
			if (gsm_decode(r, s, d)) {
				fprintf(stderr, "%s: bad frame in %s\n", 
					progname, inname ? inname : "stdin");
				gsm_destroy(r);
				errno = 0;
				return -1;
			}
			t_stop = gettime();
			t_gsm_decode += calc_timediff_ms(t_start,t_stop);
		}

		if ((*output)(d) < 0) {
			perror(outname);
			fprintf(stderr, "%s: error writing to %s\n",
					progname, outname);
			gsm_destroy(r);
			return -1;
		}
	}
	
	/* MiBencHybrid Kill Threads */
	t_start = gettime();
	// terminate all threads
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "Sending terminate message to %i threads:\n", running_threads);
	fflush(stdout);
	#endif
	for (i=0; i<running_threads; i++)
	{
	  #ifndef _MIBENCHOUTPUT
	  fprintf(stderr, " %i",i);fflush(stdout);
	  #endif
	  indata[0] = UINT_MAX;
	  indata[1] = UINT_MAX;
	  indata[2] = UINT_MAX;
	  indata[3] = UINT_MAX;
	  indata[4] = UINT_MAX;
	
	  rq_send(&rq_SENDING, indata, INDATA_LEN*sizeof(uint32));
	}
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "\n");
	
	fprintf(stderr, "Waiting for termination...\n");
	#endif

#ifdef SHADOWING
	join_threads_shadowing(sh, running_threads);
#else
	join_threads(sw_threads, swt, hw_threads, hwt);
#endif
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "\n");
	#endif
	
	t_stop = gettime();
	t_terminate_threads = calc_timediff_ms(t_start,t_stop);
	/* END: MiBenchHybrid Kill Threads */
	
	#ifdef _PRINT_TIMES
	/* print times*/
	if(f_hybrid)
	{
		fprintf(stderr, "Running times (%d sw-threads, %d hw-threads):\n",sw_threads, hw_threads);
	}
	else
	{
		fprintf(stderr, "Running times (normal MiBench):\n");
	}
	fprintf(stderr,  
		"\tgenerate threads\t: %lu ms\n"
		"\tgsm_decode\t\t: %lu ms\n"
		"\tterminate threads\t: %lu ms\n"
		"\tsum\t: %lu ms\n",
		t_generate_threads,
		t_gsm_decode,
		t_terminate_threads,
		t_generate_threads+t_gsm_decode+t_terminate_threads
	);
	#endif

	if (cc < 0) {
		perror(inname ? inname : "stdin" );
		fprintf(stderr, "%s: error reading from %s\n", progname,
			inname ? inname : "stdin");
		gsm_destroy(r);
		return -1;
	}

	gsm_destroy(r);
	return 0;
}

static int process P1((name), char * name)
{
	int step = 0;

	out     = (FILE *)0;
	in      = (FILE *)0;

	outname = (char *)0;
	inname  = (char *)0;

	if (!open_input(name, &instat) || !open_output(name))
		goto err;

	if ((*(f_decode ? init_output    : init_input))()) {
		fprintf(stderr, "%s: error %s %s\n",
			progname,
			f_decode ? "writing header to" : "reading header from",
			f_decode ? (outname ? outname : "stdout")
				 : (inname ? inname : "stdin"));
		goto err;
	}

	if ((*(f_decode ? process_decode : process_encode))())
		goto err;

	if (fflush(out) < 0 || ferror(out)) {
		perror(outname ? outname : "stdout");
		fprintf(stderr, "%s: error writing \"%s\"\n", progname,
				outname ? outname:"stdout");
		goto err;
	}

	if (out != stdout) {

		update_times();
		update_mode ();
		update_own  ();

		if (fclose(out) < 0) {
			perror(outname);
			fprintf(stderr, "%s: error writing \"%s\"\n",
				progname, outname);
			goto err;
		}
		if (outname != name) free(outname);
		outname = (char *)0;
	}
	out = (FILE *)0;
	if (in  != stdin) {
		(void)fclose(in), in = (FILE *)0;
		if (!f_cat && !f_precious) {
			if (unlink(inname) < 0) {
				perror(inname);
				fprintf(stderr,
					"%s: source \"%s\" not deleted.\n",
					progname, inname);
			}
			goto err;
		}
		if (inname != name) free(inname);
		inname = (char *)0;
	}
	return 0;

	/*
	 *  Error handling and cleanup: 
	 *  - error out: close out, unlink it, close in, free the names.
	 *  - 
	 */
err:
	if (out && out != stdout) {
		(void)fclose(out), out = (FILE *)0;
		if (unlink(outname) < 0 && errno != ENOENT && errno != EINTR) {
			perror(outname);
			fprintf(stderr, "%s: could not unlink \"%s\"\n",
				progname, outname);
		}
	}
	if (in && in != stdin) (void)fclose(in), in = (FILE *)0;

	if (inname  && inname  != name) free(inname);
	if (outname && outname != name) free(outname);

	return -1;
}

static void version P0()
{
	printf( "%s 1.0, version %s\n",
		progname,
		"$Id: toast.c,v 1.1.1.1 2000/11/06 19:54:26 mguthaus Exp $" );
}

static void help P0()
{
#ifdef SHADOWING
	fprintf(stderr,"Usage: %s [-fcpdhvuaslFSH] [sw_threads] [hw_threads] [files...] (-h for help)\n", progname);
#else
	fprintf(stderr,"Usage: %s [-fcpdhvuaslFH] [sw_threads] [hw_threads] [files...] (-h for help)\n", progname);
#endif

	fprintf(stderr,"\n");

	fprintf(stderr," -f  force     Replace existing files without asking\n");
	fprintf(stderr," -c  cat       Write to stdout, do not remove source files\n");
	fprintf(stderr," -d  decode    Decode data (default is encode)\n");
	fprintf(stderr," -p  precious  Do not delete the source\n");
	fprintf(stderr," -H  Hybrid    Run the Hybridvariant\n");	/*MiBenchHybrid*/
#ifdef SHADOWING
	fprintf(stderr," -S  Shadowing Enables thread shadowing error detection\n");
#endif // SHADOWING
	fprintf(stderr,"\n");

	fprintf(stderr," -u  u-law     Force 8 kHz/8 bit u-law in/output format\n");
	fprintf(stderr," -s  sun .au   Force Sun .au u-law in/output format\n");
	fprintf(stderr," -a  A-law     Force 8 kHz/8 bit A-law in/output format\n");
	fprintf(stderr," -l  linear    Force 16 bit linear in/output format\n");
	fprintf(stderr,"\n");

	fprintf(stderr," -F  fast      Sacrifice conformance to performance\n");
	fprintf(stderr," -v  version   Show version information\n");
	fprintf(stderr," -h  help      Print this text\n");
	fprintf(stderr,"\n");
}


static void set_format P1((f), struct fmtdesc * f)
{
	if (f_format && f_format != f) {
		fprintf( stderr,
	"%s: only one of -[uals] is possible (%s -h for help)\n",
			progname, progname);
		exit(1);
	}

	f_format = f;
}

int main P2((ac, av), int ac, char **av)
{
	int  		opt;
	extern int	optind;
	
	int running_threads;			/*MiBenchHybrid*/

	parse_argv0( *av );

#ifdef SHADOWING
	while ((opt = getopt(ac, av, "fcdpvhuaslVFSH")) != EOF)
#else
	while ((opt = getopt(ac, av, "fcdpvhuaslVFH")) != EOF)
#endif
	switch (opt) {

	case 'd': f_decode   = 1; break;
	case 'f': f_force    = 1; break;
	case 'c': f_cat      = 1; break;
	case 'p': f_precious = 1; break;
	case 'F': f_fast     = 1; break;
	case 'H': f_hybrid   = 1; break;/*MiBenchHybrid*/
#ifdef SHADOWING
	case 'S': f_shadowing = 1; break;/*MiBenchHybrid*/
#endif

#ifndef	NDEBUG
	case 'V': f_verbose  = 1; break;	/* undocumented */
#endif

	case 'u': set_format( &f_ulaw   ); break;
	case 'l': set_format( &f_linear ); break;
	case 'a': set_format( &f_alaw	); break;
	case 's': set_format( &f_audio  ); break;

	case 'v': version(); exit(0);
	case 'h': help();    exit(0);

	default: 
		fprintf(stderr,
#ifdef SHADOWING
			"Usage: %s [-fcpdhvuaslFSH] [sw_threads] [hw_threads] [files...] (-h for help)\n",
#else
			"Usage: %s [-fcpdhvuaslFSH] [sw_threads] [hw_threads] [files...] (-h for help)\n",
#endif
			progname);
		exit(1);
	}

	f_precious |= f_cat;

	av += optind;
	ac -= optind;
	
	/* MiBenchHybrid get arguments */
	if(f_hybrid)
	{
		/*get number of Software- and Hardwarethreads*/
		if(!string_is_number(*av))
		{
			help();
			exit(0);
		}
		sw_threads = atoi(*av);
		av++;
		ac--;
		
		if(!string_is_number(*av))
		{
			help();
			exit(0);
		}
		hw_threads = atoi(*av);
		av++;
		ac--;
		
		//fprintf(stderr,"Hybride Ausfuehrung mit %d Softwarethreads und %d Hardwarethreads\n",sw_threads,hw_threads);
		running_threads = sw_threads + hw_threads;
		
		if(running_threads == 0)
		{
			f_hybrid = FALSE;
		}
		if (hw_threads > NSHORT_TERM_THREADS)
		{
			fprintf(stderr,"To many Hardwarethreads!\n\n");
			help();
			exit(1);
		}
		else if (running_threads > MAX_THREADS)
		{
			fprintf(stderr,"To many Threads!\n\n");
			help();
			exit(1);
		}
	}
	/* END: MiBenchHybrid get arguments */

	catch_signals(onintr);

	if (ac <= 0) process( (char *)0 );
	else while (ac--) process( *av++ );

	exit(0);
}
