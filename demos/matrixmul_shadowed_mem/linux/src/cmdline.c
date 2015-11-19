/*
  File autogenerated by gengetopt version 2.22.5
  generated with the following command:
  gengetopt 

  The developers of gengetopt consider the fixed text that goes in all
  gengetopt output files to be in the public domain:
  we make no copyright claims on it.
*/

/* If we use autoconf.  */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef FIX_UNUSED
#define FIX_UNUSED(X) (void) (X) /* avoid warnings for unused params */
#endif

#include <getopt.h>

#include "cmdline.h"

const char *gengetopt_args_info_purpose = "A demo application for the ReconOS system with shadowing which sorts blocks of \ndata.";

const char *gengetopt_args_info_usage = "Usage: matrixmul [OPTIONS]...";

const char *gengetopt_args_info_description = "";

const char *gengetopt_args_info_detailed_help[] = {
  "      --help                    Print help and exit",
  "      --detailed-help           Print help, including all details and hidden \n                                  options, and exit",
  "  -V, --version                 Print version and exit",
  "  -h, --hwt=number              Number of HW Threads used for matrix \n                                  multiplication.",
  "  -s, --swt=number              Number of SW Threads used for matrix \n                                  multiplication.",
  "  -m, --mt=number               Number of MainCPU Threads used for matrix \n                                  multiplication.  (default=`0')",
  "  -b, --matrix-size=number      Size of matrices to multiply. Only powers of 2, \n                                  bigger than 128 allowed. Default is 512.  \n                                  (possible values=\"256\", \"512\", \"1024\", \n                                  \"2048\" default=`512')",
  "  -t, --thread-interface=number Which interface shall be used to communicate \n                                  with worker threads?  (possible values=\"0\", \n                                  \"1\", \"2\" default=`0')",
  "  0= SHMEM, 1= MBOX, 2= RQUEUE",
  "      --level=number            Shadowing level. Controls which error detection \n                                  techniques are used.  (possible values=\"1\", \n                                  \"2\", \"3\" default=`3')",
  "\n Group: file ops",
  "  -f, --read-matrices           Read input matrices and precomputed output \n                                  matrix from files",
  "  -w, --write-matrices          Write out input matrices and poutput matrix to \n                                  files",
  "\nShadowing Options:",
  "  Activate and configure the shadow subsystem",
  "  -a, --shadow                  Activates the shadowing subsystem.  \n                                  (default=off)",
  "  -c, --shadow-schedule=algorithm\n                                Determines the algorithm of the shadow \n                                  scheduler.  (possible values=\"0\", \"1\" \n                                  default=`0')",
  "  -r, --shadow-transmodal       Uses shadow threads of opposite modality.  \n                                  (default=off)",
  "  -E, --shadow-arb-err-det      Enable error detection in memory access \n                                  arbiter.  (default=off)",
  "  -B, --shadow-arb-buf-size=exponent\n                                How much memory should be used to buffer memory \n                                  requests? 0^= 1KB ... 7^= 128KB  (possible \n                                  values=\"0\", \"1\", \"2\", \"3\", \"4\", \n                                  \"5\", \"6\", \"7\" default=`3')",
    0
};

static void
init_help_array(void)
{
  gengetopt_args_info_help[0] = gengetopt_args_info_detailed_help[0];
  gengetopt_args_info_help[1] = gengetopt_args_info_detailed_help[1];
  gengetopt_args_info_help[2] = gengetopt_args_info_detailed_help[2];
  gengetopt_args_info_help[3] = gengetopt_args_info_detailed_help[3];
  gengetopt_args_info_help[4] = gengetopt_args_info_detailed_help[4];
  gengetopt_args_info_help[5] = gengetopt_args_info_detailed_help[5];
  gengetopt_args_info_help[6] = gengetopt_args_info_detailed_help[6];
  gengetopt_args_info_help[7] = gengetopt_args_info_detailed_help[7];
  gengetopt_args_info_help[8] = gengetopt_args_info_detailed_help[9];
  gengetopt_args_info_help[9] = gengetopt_args_info_detailed_help[10];
  gengetopt_args_info_help[10] = gengetopt_args_info_detailed_help[11];
  gengetopt_args_info_help[11] = gengetopt_args_info_detailed_help[12];
  gengetopt_args_info_help[12] = gengetopt_args_info_detailed_help[13];
  gengetopt_args_info_help[13] = gengetopt_args_info_detailed_help[14];
  gengetopt_args_info_help[14] = gengetopt_args_info_detailed_help[15];
  gengetopt_args_info_help[15] = gengetopt_args_info_detailed_help[16];
  gengetopt_args_info_help[16] = gengetopt_args_info_detailed_help[17];
  gengetopt_args_info_help[17] = gengetopt_args_info_detailed_help[18];
  gengetopt_args_info_help[18] = gengetopt_args_info_detailed_help[19];
  gengetopt_args_info_help[19] = 0; 
  
}

const char *gengetopt_args_info_help[20];

typedef enum {ARG_NO
  , ARG_FLAG
  , ARG_INT
} cmdline_parser_arg_type;

static
void clear_given (struct gengetopt_args_info *args_info);
static
void clear_args (struct gengetopt_args_info *args_info);

static int
cmdline_parser_internal (int argc, char **argv, struct gengetopt_args_info *args_info,
                        struct cmdline_parser_params *params, const char *additional_error);

static int
cmdline_parser_required2 (struct gengetopt_args_info *args_info, const char *prog_name, const char *additional_error);

const char *cmdline_parser_matrix_size_values[] = {"256", "512", "1024", "2048", 0}; /*< Possible values for matrix-size. */
const char *cmdline_parser_thread_interface_values[] = {"0", "1", "2", 0}; /*< Possible values for thread-interface. */
const char *cmdline_parser_level_values[] = {"1", "2", "3", 0}; /*< Possible values for level. */
const char *cmdline_parser_shadow_schedule_values[] = {"0", "1", 0}; /*< Possible values for shadow-schedule. */
const char *cmdline_parser_shadow_arb_buf_size_values[] = {"0", "1", "2", "3", "4", "5", "6", "7", 0}; /*< Possible values for shadow-arb-buf-size. */

static char *
gengetopt_strdup (const char *s);

static
void clear_given (struct gengetopt_args_info *args_info)
{
  args_info->help_given = 0 ;
  args_info->detailed_help_given = 0 ;
  args_info->version_given = 0 ;
  args_info->hwt_given = 0 ;
  args_info->swt_given = 0 ;
  args_info->mt_given = 0 ;
  args_info->matrix_size_given = 0 ;
  args_info->thread_interface_given = 0 ;
  args_info->level_given = 0 ;
  args_info->read_matrices_given = 0 ;
  args_info->write_matrices_given = 0 ;
  args_info->shadow_given = 0 ;
  args_info->shadow_schedule_given = 0 ;
  args_info->shadow_transmodal_given = 0 ;
  args_info->shadow_arb_err_det_given = 0 ;
  args_info->shadow_arb_buf_size_given = 0 ;
  args_info->file_ops_group_counter = 0 ;
}

static
void clear_args (struct gengetopt_args_info *args_info)
{
  FIX_UNUSED (args_info);
  args_info->hwt_orig = NULL;
  args_info->swt_orig = NULL;
  args_info->mt_arg = 0;
  args_info->mt_orig = NULL;
  args_info->matrix_size_arg = 512;
  args_info->matrix_size_orig = NULL;
  args_info->thread_interface_arg = 0;
  args_info->thread_interface_orig = NULL;
  args_info->level_arg = 3;
  args_info->level_orig = NULL;
  args_info->shadow_flag = 0;
  args_info->shadow_schedule_arg = 0;
  args_info->shadow_schedule_orig = NULL;
  args_info->shadow_transmodal_flag = 0;
  args_info->shadow_arb_err_det_flag = 0;
  args_info->shadow_arb_buf_size_arg = 3;
  args_info->shadow_arb_buf_size_orig = NULL;
  
}

static
void init_args_info(struct gengetopt_args_info *args_info)
{

  init_help_array(); 
  args_info->help_help = gengetopt_args_info_detailed_help[0] ;
  args_info->detailed_help_help = gengetopt_args_info_detailed_help[1] ;
  args_info->version_help = gengetopt_args_info_detailed_help[2] ;
  args_info->hwt_help = gengetopt_args_info_detailed_help[3] ;
  args_info->swt_help = gengetopt_args_info_detailed_help[4] ;
  args_info->mt_help = gengetopt_args_info_detailed_help[5] ;
  args_info->matrix_size_help = gengetopt_args_info_detailed_help[6] ;
  args_info->thread_interface_help = gengetopt_args_info_detailed_help[7] ;
  args_info->level_help = gengetopt_args_info_detailed_help[9] ;
  args_info->read_matrices_help = gengetopt_args_info_detailed_help[11] ;
  args_info->write_matrices_help = gengetopt_args_info_detailed_help[12] ;
  args_info->shadow_help = gengetopt_args_info_detailed_help[15] ;
  args_info->shadow_schedule_help = gengetopt_args_info_detailed_help[16] ;
  args_info->shadow_transmodal_help = gengetopt_args_info_detailed_help[17] ;
  args_info->shadow_arb_err_det_help = gengetopt_args_info_detailed_help[18] ;
  args_info->shadow_arb_buf_size_help = gengetopt_args_info_detailed_help[19] ;
  
}

void
cmdline_parser_print_version (void)
{
  printf ("%s %s\n",
     (strlen(CMDLINE_PARSER_PACKAGE_NAME) ? CMDLINE_PARSER_PACKAGE_NAME : CMDLINE_PARSER_PACKAGE),
     CMDLINE_PARSER_VERSION);
}

static void print_help_common(void) {
  cmdline_parser_print_version ();

  if (strlen(gengetopt_args_info_purpose) > 0)
    printf("\n%s\n", gengetopt_args_info_purpose);

  if (strlen(gengetopt_args_info_usage) > 0)
    printf("\n%s\n", gengetopt_args_info_usage);

  printf("\n");

  if (strlen(gengetopt_args_info_description) > 0)
    printf("%s\n\n", gengetopt_args_info_description);
}

void
cmdline_parser_print_help (void)
{
  int i = 0;
  print_help_common();
  while (gengetopt_args_info_help[i])
    printf("%s\n", gengetopt_args_info_help[i++]);
}

void
cmdline_parser_print_detailed_help (void)
{
  int i = 0;
  print_help_common();
  while (gengetopt_args_info_detailed_help[i])
    printf("%s\n", gengetopt_args_info_detailed_help[i++]);
}

void
cmdline_parser_init (struct gengetopt_args_info *args_info)
{
  clear_given (args_info);
  clear_args (args_info);
  init_args_info (args_info);
}

void
cmdline_parser_params_init(struct cmdline_parser_params *params)
{
  if (params)
    { 
      params->override = 0;
      params->initialize = 1;
      params->check_required = 1;
      params->check_ambiguity = 0;
      params->print_errors = 1;
    }
}

struct cmdline_parser_params *
cmdline_parser_params_create(void)
{
  struct cmdline_parser_params *params = 
    (struct cmdline_parser_params *)malloc(sizeof(struct cmdline_parser_params));
  cmdline_parser_params_init(params);  
  return params;
}

static void
free_string_field (char **s)
{
  if (*s)
    {
      free (*s);
      *s = 0;
    }
}


static void
cmdline_parser_release (struct gengetopt_args_info *args_info)
{

  free_string_field (&(args_info->hwt_orig));
  free_string_field (&(args_info->swt_orig));
  free_string_field (&(args_info->mt_orig));
  free_string_field (&(args_info->matrix_size_orig));
  free_string_field (&(args_info->thread_interface_orig));
  free_string_field (&(args_info->level_orig));
  free_string_field (&(args_info->shadow_schedule_orig));
  free_string_field (&(args_info->shadow_arb_buf_size_orig));
  
  

  clear_given (args_info);
}

/**
 * @param val the value to check
 * @param values the possible values
 * @return the index of the matched value:
 * -1 if no value matched,
 * -2 if more than one value has matched
 */
static int
check_possible_values(const char *val, const char *values[])
{
  int i, found, last;
  size_t len;

  if (!val)   /* otherwise strlen() crashes below */
    return -1; /* -1 means no argument for the option */

  found = last = 0;

  for (i = 0, len = strlen(val); values[i]; ++i)
    {
      if (strncmp(val, values[i], len) == 0)
        {
          ++found;
          last = i;
          if (strlen(values[i]) == len)
            return i; /* exact macth no need to check more */
        }
    }

  if (found == 1) /* one match: OK */
    return last;

  return (found ? -2 : -1); /* return many values or none matched */
}


static void
write_into_file(FILE *outfile, const char *opt, const char *arg, const char *values[])
{
  int found = -1;
  if (arg) {
    if (values) {
      found = check_possible_values(arg, values);      
    }
    if (found >= 0)
      fprintf(outfile, "%s=\"%s\" # %s\n", opt, arg, values[found]);
    else
      fprintf(outfile, "%s=\"%s\"\n", opt, arg);
  } else {
    fprintf(outfile, "%s\n", opt);
  }
}


int
cmdline_parser_dump(FILE *outfile, struct gengetopt_args_info *args_info)
{
  int i = 0;

  if (!outfile)
    {
      fprintf (stderr, "%s: cannot dump options to stream\n", CMDLINE_PARSER_PACKAGE);
      return EXIT_FAILURE;
    }

  if (args_info->help_given)
    write_into_file(outfile, "help", 0, 0 );
  if (args_info->detailed_help_given)
    write_into_file(outfile, "detailed-help", 0, 0 );
  if (args_info->version_given)
    write_into_file(outfile, "version", 0, 0 );
  if (args_info->hwt_given)
    write_into_file(outfile, "hwt", args_info->hwt_orig, 0);
  if (args_info->swt_given)
    write_into_file(outfile, "swt", args_info->swt_orig, 0);
  if (args_info->mt_given)
    write_into_file(outfile, "mt", args_info->mt_orig, 0);
  if (args_info->matrix_size_given)
    write_into_file(outfile, "matrix-size", args_info->matrix_size_orig, cmdline_parser_matrix_size_values);
  if (args_info->thread_interface_given)
    write_into_file(outfile, "thread-interface", args_info->thread_interface_orig, cmdline_parser_thread_interface_values);
  if (args_info->level_given)
    write_into_file(outfile, "level", args_info->level_orig, cmdline_parser_level_values);
  if (args_info->read_matrices_given)
    write_into_file(outfile, "read-matrices", 0, 0 );
  if (args_info->write_matrices_given)
    write_into_file(outfile, "write-matrices", 0, 0 );
  if (args_info->shadow_given)
    write_into_file(outfile, "shadow", 0, 0 );
  if (args_info->shadow_schedule_given)
    write_into_file(outfile, "shadow-schedule", args_info->shadow_schedule_orig, cmdline_parser_shadow_schedule_values);
  if (args_info->shadow_transmodal_given)
    write_into_file(outfile, "shadow-transmodal", 0, 0 );
  if (args_info->shadow_arb_err_det_given)
    write_into_file(outfile, "shadow-arb-err-det", 0, 0 );
  if (args_info->shadow_arb_buf_size_given)
    write_into_file(outfile, "shadow-arb-buf-size", args_info->shadow_arb_buf_size_orig, cmdline_parser_shadow_arb_buf_size_values);
  

  i = EXIT_SUCCESS;
  return i;
}

int
cmdline_parser_file_save(const char *filename, struct gengetopt_args_info *args_info)
{
  FILE *outfile;
  int i = 0;

  outfile = fopen(filename, "w");

  if (!outfile)
    {
      fprintf (stderr, "%s: cannot open file for writing: %s\n", CMDLINE_PARSER_PACKAGE, filename);
      return EXIT_FAILURE;
    }

  i = cmdline_parser_dump(outfile, args_info);
  fclose (outfile);

  return i;
}

void
cmdline_parser_free (struct gengetopt_args_info *args_info)
{
  cmdline_parser_release (args_info);
}

/** @brief replacement of strdup, which is not standard */
char *
gengetopt_strdup (const char *s)
{
  char *result = 0;
  if (!s)
    return result;

  result = (char*)malloc(strlen(s) + 1);
  if (result == (char*)0)
    return (char*)0;
  strcpy(result, s);
  return result;
}

static void
reset_group_file_ops(struct gengetopt_args_info *args_info)
{
  if (! args_info->file_ops_group_counter)
    return;
  
  args_info->read_matrices_given = 0 ;
  args_info->write_matrices_given = 0 ;

  args_info->file_ops_group_counter = 0;
}

int
cmdline_parser (int argc, char **argv, struct gengetopt_args_info *args_info)
{
  return cmdline_parser2 (argc, argv, args_info, 0, 1, 1);
}

int
cmdline_parser_ext (int argc, char **argv, struct gengetopt_args_info *args_info,
                   struct cmdline_parser_params *params)
{
  int result;
  result = cmdline_parser_internal (argc, argv, args_info, params, 0);

  if (result == EXIT_FAILURE)
    {
      cmdline_parser_free (args_info);
      exit (EXIT_FAILURE);
    }
  
  return result;
}

int
cmdline_parser2 (int argc, char **argv, struct gengetopt_args_info *args_info, int override, int initialize, int check_required)
{
  int result;
  struct cmdline_parser_params params;
  
  params.override = override;
  params.initialize = initialize;
  params.check_required = check_required;
  params.check_ambiguity = 0;
  params.print_errors = 1;

  result = cmdline_parser_internal (argc, argv, args_info, &params, 0);

  if (result == EXIT_FAILURE)
    {
      cmdline_parser_free (args_info);
      exit (EXIT_FAILURE);
    }
  
  return result;
}

int
cmdline_parser_required (struct gengetopt_args_info *args_info, const char *prog_name)
{
  int result = EXIT_SUCCESS;

  if (cmdline_parser_required2(args_info, prog_name, 0) > 0)
    result = EXIT_FAILURE;

  if (result == EXIT_FAILURE)
    {
      cmdline_parser_free (args_info);
      exit (EXIT_FAILURE);
    }
  
  return result;
}

int
cmdline_parser_required2 (struct gengetopt_args_info *args_info, const char *prog_name, const char *additional_error)
{
  int error = 0;
  FIX_UNUSED (additional_error);

  /* checks for required options */
  if (! args_info->hwt_given)
    {
      fprintf (stderr, "%s: '--hwt' ('-h') option required%s\n", prog_name, (additional_error ? additional_error : ""));
      error = 1;
    }
  
  if (! args_info->swt_given)
    {
      fprintf (stderr, "%s: '--swt' ('-s') option required%s\n", prog_name, (additional_error ? additional_error : ""));
      error = 1;
    }
  
  
  /* checks for dependences among options */
  if (args_info->shadow_schedule_given && ! args_info->shadow_given)
    {
      fprintf (stderr, "%s: '--shadow-schedule' ('-c') option depends on option 'shadow'%s\n", prog_name, (additional_error ? additional_error : ""));
      error = 1;
    }
  if (args_info->shadow_arb_buf_size_given && ! args_info->shadow_given)
    {
      fprintf (stderr, "%s: '--shadow-arb-buf-size' ('-B') option depends on option 'shadow'%s\n", prog_name, (additional_error ? additional_error : ""));
      error = 1;
    }

  return error;
}


static char *package_name = 0;

/**
 * @brief updates an option
 * @param field the generic pointer to the field to update
 * @param orig_field the pointer to the orig field
 * @param field_given the pointer to the number of occurrence of this option
 * @param prev_given the pointer to the number of occurrence already seen
 * @param value the argument for this option (if null no arg was specified)
 * @param possible_values the possible values for this option (if specified)
 * @param default_value the default value (in case the option only accepts fixed values)
 * @param arg_type the type of this option
 * @param check_ambiguity @see cmdline_parser_params.check_ambiguity
 * @param override @see cmdline_parser_params.override
 * @param no_free whether to free a possible previous value
 * @param multiple_option whether this is a multiple option
 * @param long_opt the corresponding long option
 * @param short_opt the corresponding short option (or '-' if none)
 * @param additional_error possible further error specification
 */
static
int update_arg(void *field, char **orig_field,
               unsigned int *field_given, unsigned int *prev_given, 
               char *value, const char *possible_values[],
               const char *default_value,
               cmdline_parser_arg_type arg_type,
               int check_ambiguity, int override,
               int no_free, int multiple_option,
               const char *long_opt, char short_opt,
               const char *additional_error)
{
  char *stop_char = 0;
  const char *val = value;
  int found;
  FIX_UNUSED (field);

  stop_char = 0;
  found = 0;

  if (!multiple_option && prev_given && (*prev_given || (check_ambiguity && *field_given)))
    {
      if (short_opt != '-')
        fprintf (stderr, "%s: `--%s' (`-%c') option given more than once%s\n", 
               package_name, long_opt, short_opt,
               (additional_error ? additional_error : ""));
      else
        fprintf (stderr, "%s: `--%s' option given more than once%s\n", 
               package_name, long_opt,
               (additional_error ? additional_error : ""));
      return 1; /* failure */
    }

  if (possible_values && (found = check_possible_values((value ? value : default_value), possible_values)) < 0)
    {
      if (short_opt != '-')
        fprintf (stderr, "%s: %s argument, \"%s\", for option `--%s' (`-%c')%s\n", 
          package_name, (found == -2) ? "ambiguous" : "invalid", value, long_opt, short_opt,
          (additional_error ? additional_error : ""));
      else
        fprintf (stderr, "%s: %s argument, \"%s\", for option `--%s'%s\n", 
          package_name, (found == -2) ? "ambiguous" : "invalid", value, long_opt,
          (additional_error ? additional_error : ""));
      return 1; /* failure */
    }
    
  if (field_given && *field_given && ! override)
    return 0;
  if (prev_given)
    (*prev_given)++;
  if (field_given)
    (*field_given)++;
  if (possible_values)
    val = possible_values[found];

  switch(arg_type) {
  case ARG_FLAG:
    *((int *)field) = !*((int *)field);
    break;
  case ARG_INT:
    if (val) *((int *)field) = strtol (val, &stop_char, 0);
    break;
  default:
    break;
  };

  /* check numeric conversion */
  switch(arg_type) {
  case ARG_INT:
    if (val && !(stop_char && *stop_char == '\0')) {
      fprintf(stderr, "%s: invalid numeric value: %s\n", package_name, val);
      return 1; /* failure */
    }
    break;
  default:
    ;
  };

  /* store the original value */
  switch(arg_type) {
  case ARG_NO:
  case ARG_FLAG:
    break;
  default:
    if (value && orig_field) {
      if (no_free) {
        *orig_field = value;
      } else {
        if (*orig_field)
          free (*orig_field); /* free previous string */
        *orig_field = gengetopt_strdup (value);
      }
    }
  };

  return 0; /* OK */
}


int
cmdline_parser_internal (
  int argc, char **argv, struct gengetopt_args_info *args_info,
                        struct cmdline_parser_params *params, const char *additional_error)
{
  int c;	/* Character of the parsed option.  */

  int error = 0;
  struct gengetopt_args_info local_args_info;
  
  int override;
  int initialize;
  int check_required;
  int check_ambiguity;
  
  package_name = argv[0];
  
  override = params->override;
  initialize = params->initialize;
  check_required = params->check_required;
  check_ambiguity = params->check_ambiguity;

  if (initialize)
    cmdline_parser_init (args_info);

  cmdline_parser_init (&local_args_info);

  optarg = 0;
  optind = 0;
  opterr = params->print_errors;
  optopt = '?';

  while (1)
    {
      int option_index = 0;

      static struct option long_options[] = {
        { "help",	0, NULL, 0 },
        { "detailed-help",	0, NULL, 0 },
        { "version",	0, NULL, 'V' },
        { "hwt",	1, NULL, 'h' },
        { "swt",	1, NULL, 's' },
        { "mt",	1, NULL, 'm' },
        { "matrix-size",	1, NULL, 'b' },
        { "thread-interface",	1, NULL, 't' },
        { "level",	1, NULL, 0 },
        { "read-matrices",	0, NULL, 'f' },
        { "write-matrices",	0, NULL, 'w' },
        { "shadow",	0, NULL, 'a' },
        { "shadow-schedule",	1, NULL, 'c' },
        { "shadow-transmodal",	0, NULL, 'r' },
        { "shadow-arb-err-det",	0, NULL, 'E' },
        { "shadow-arb-buf-size",	1, NULL, 'B' },
        { 0,  0, 0, 0 }
      };

      c = getopt_long (argc, argv, "Vh:s:m:b:t:fwac:rEB:", long_options, &option_index);

      if (c == -1) break;	/* Exit from `while (1)' loop.  */

      switch (c)
        {
        case 'V':	/* Print version and exit.  */
          cmdline_parser_print_version ();
          cmdline_parser_free (&local_args_info);
          exit (EXIT_SUCCESS);

        case 'h':	/* Number of HW Threads used for matrix multiplication..  */
        
        
          if (update_arg( (void *)&(args_info->hwt_arg), 
               &(args_info->hwt_orig), &(args_info->hwt_given),
              &(local_args_info.hwt_given), optarg, 0, 0, ARG_INT,
              check_ambiguity, override, 0, 0,
              "hwt", 'h',
              additional_error))
            goto failure;
        
          break;
        case 's':	/* Number of SW Threads used for matrix multiplication..  */
        
        
          if (update_arg( (void *)&(args_info->swt_arg), 
               &(args_info->swt_orig), &(args_info->swt_given),
              &(local_args_info.swt_given), optarg, 0, 0, ARG_INT,
              check_ambiguity, override, 0, 0,
              "swt", 's',
              additional_error))
            goto failure;
        
          break;
        case 'm':	/* Number of MainCPU Threads used for matrix multiplication..  */
        
        
          if (update_arg( (void *)&(args_info->mt_arg), 
               &(args_info->mt_orig), &(args_info->mt_given),
              &(local_args_info.mt_given), optarg, 0, "0", ARG_INT,
              check_ambiguity, override, 0, 0,
              "mt", 'm',
              additional_error))
            goto failure;
        
          break;
        case 'b':	/* Size of matrices to multiply. Only powers of 2, bigger than 128 allowed. Default is 512..  */
        
        
          if (update_arg( (void *)&(args_info->matrix_size_arg), 
               &(args_info->matrix_size_orig), &(args_info->matrix_size_given),
              &(local_args_info.matrix_size_given), optarg, cmdline_parser_matrix_size_values, "512", ARG_INT,
              check_ambiguity, override, 0, 0,
              "matrix-size", 'b',
              additional_error))
            goto failure;
        
          break;
        case 't':	/* Which interface shall be used to communicate with worker threads?.  */
        
        
          if (update_arg( (void *)&(args_info->thread_interface_arg), 
               &(args_info->thread_interface_orig), &(args_info->thread_interface_given),
              &(local_args_info.thread_interface_given), optarg, cmdline_parser_thread_interface_values, "0", ARG_INT,
              check_ambiguity, override, 0, 0,
              "thread-interface", 't',
              additional_error))
            goto failure;
        
          break;
        case 'f':	/* Read input matrices and precomputed output matrix from files.  */
        
          if (args_info->file_ops_group_counter && override)
            reset_group_file_ops (args_info);
          args_info->file_ops_group_counter += 1;
        
          if (update_arg( 0 , 
               0 , &(args_info->read_matrices_given),
              &(local_args_info.read_matrices_given), optarg, 0, 0, ARG_NO,
              check_ambiguity, override, 0, 0,
              "read-matrices", 'f',
              additional_error))
            goto failure;
        
          break;
        case 'w':	/* Write out input matrices and poutput matrix to files.  */
        
          if (args_info->file_ops_group_counter && override)
            reset_group_file_ops (args_info);
          args_info->file_ops_group_counter += 1;
        
          if (update_arg( 0 , 
               0 , &(args_info->write_matrices_given),
              &(local_args_info.write_matrices_given), optarg, 0, 0, ARG_NO,
              check_ambiguity, override, 0, 0,
              "write-matrices", 'w',
              additional_error))
            goto failure;
        
          break;
        case 'a':	/* Activates the shadowing subsystem..  */
        
        
          if (update_arg((void *)&(args_info->shadow_flag), 0, &(args_info->shadow_given),
              &(local_args_info.shadow_given), optarg, 0, 0, ARG_FLAG,
              check_ambiguity, override, 1, 0, "shadow", 'a',
              additional_error))
            goto failure;
        
          break;
        case 'c':	/* Determines the algorithm of the shadow scheduler..  */
        
        
          if (update_arg( (void *)&(args_info->shadow_schedule_arg), 
               &(args_info->shadow_schedule_orig), &(args_info->shadow_schedule_given),
              &(local_args_info.shadow_schedule_given), optarg, cmdline_parser_shadow_schedule_values, "0", ARG_INT,
              check_ambiguity, override, 0, 0,
              "shadow-schedule", 'c',
              additional_error))
            goto failure;
        
          break;
        case 'r':	/* Uses shadow threads of opposite modality..  */
        
        
          if (update_arg((void *)&(args_info->shadow_transmodal_flag), 0, &(args_info->shadow_transmodal_given),
              &(local_args_info.shadow_transmodal_given), optarg, 0, 0, ARG_FLAG,
              check_ambiguity, override, 1, 0, "shadow-transmodal", 'r',
              additional_error))
            goto failure;
        
          break;
        case 'E':	/* Enable error detection in memory access arbiter..  */
        
        
          if (update_arg((void *)&(args_info->shadow_arb_err_det_flag), 0, &(args_info->shadow_arb_err_det_given),
              &(local_args_info.shadow_arb_err_det_given), optarg, 0, 0, ARG_FLAG,
              check_ambiguity, override, 1, 0, "shadow-arb-err-det", 'E',
              additional_error))
            goto failure;
        
          break;
        case 'B':	/* How much memory should be used to buffer memory requests? 0^= 1KB ... 7^= 128KB.  */
        
        
          if (update_arg( (void *)&(args_info->shadow_arb_buf_size_arg), 
               &(args_info->shadow_arb_buf_size_orig), &(args_info->shadow_arb_buf_size_given),
              &(local_args_info.shadow_arb_buf_size_given), optarg, cmdline_parser_shadow_arb_buf_size_values, "3", ARG_INT,
              check_ambiguity, override, 0, 0,
              "shadow-arb-buf-size", 'B',
              additional_error))
            goto failure;
        
          break;

        case 0:	/* Long option with no short option */
          if (strcmp (long_options[option_index].name, "help") == 0) {
            cmdline_parser_print_help ();
            cmdline_parser_free (&local_args_info);
            exit (EXIT_SUCCESS);
          }

          if (strcmp (long_options[option_index].name, "detailed-help") == 0) {
            cmdline_parser_print_detailed_help ();
            cmdline_parser_free (&local_args_info);
            exit (EXIT_SUCCESS);
          }

          /* Shadowing level. Controls which error detection techniques are used..  */
          if (strcmp (long_options[option_index].name, "level") == 0)
          {
          
          
            if (update_arg( (void *)&(args_info->level_arg), 
                 &(args_info->level_orig), &(args_info->level_given),
                &(local_args_info.level_given), optarg, cmdline_parser_level_values, "3", ARG_INT,
                check_ambiguity, override, 0, 0,
                "level", '-',
                additional_error))
              goto failure;
          
          }
          
          break;
        case '?':	/* Invalid option.  */
          /* `getopt_long' already printed an error message.  */
          goto failure;

        default:	/* bug: option not considered.  */
          fprintf (stderr, "%s: option unknown: %c%s\n", CMDLINE_PARSER_PACKAGE, c, (additional_error ? additional_error : ""));
          abort ();
        } /* switch */
    } /* while */

  if (args_info->file_ops_group_counter > 1)
    {
      fprintf (stderr, "%s: %d options of group file ops were given. At most one is required%s.\n", argv[0], args_info->file_ops_group_counter, (additional_error ? additional_error : ""));
      error = 1;
    }
  


  if (check_required)
    {
      error += cmdline_parser_required2 (args_info, argv[0], additional_error);
    }

  cmdline_parser_release (&local_args_info);

  if ( error )
    return (EXIT_FAILURE);

  return 0;

failure:
  
  cmdline_parser_release (&local_args_info);
  return (EXIT_FAILURE);
}