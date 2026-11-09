//Provides: out_channel_redirect_stdout
var out_channel_redirect_stdout;

//Provides: out_channel_redirect_stderr
var out_channel_redirect_stderr;

//Provides: out_channel_redirect_init_channels
//Requires: out_channel_redirect_stdout, out_channel_redirect_stderr
function out_channel_redirect_init_channels(stdout, stderr) {
  out_channel_redirect_stdout = stdout;
  out_channel_redirect_stderr = stderr;
  return 0;
}

//Provides: out_channel_redirect_print_stdout
//Requires: out_channel_redirect_stdout,caml_ml_output,caml_ml_string_length,caml_string_of_jsbytes
function out_channel_redirect_print_stdout(unit) {
  var s = caml_string_of_jsbytes("stdout from external");
  caml_ml_output(out_channel_redirect_stdout, s, 0, caml_ml_string_length(s));
  return 0
}

//Provides: out_channel_redirect_print_stderr
//Requires: out_channel_redirect_stderr,caml_ml_output,caml_ml_string_length,caml_string_of_jsbytes
function out_channel_redirect_print_stderr(unit) {
  var s = caml_string_of_jsbytes("stderr from external");
  caml_ml_output(out_channel_redirect_stderr, s, 0, caml_ml_string_length(s));
  return 0
}

//Provides: out_channel_redirect_std_handles_valid
function out_channel_redirect_std_handles_valid(unit) {
  return 1;
}
