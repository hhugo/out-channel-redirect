#include <stdio.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <unistd.h>
#ifdef _WIN32
#include <windows.h>
#include <io.h>

/* Mimic what [Unix.stdout] and [Unix.stderr] do: cache the HANDLEs of the
   standard fds at startup. */
static HANDLE std_handles[3];
static DWORD std_types[3];
#endif

CAMLprim value out_channel_redirect_init_channels(value vout, value verr){
#ifdef _WIN32
  int i;
  for (i = 0; i < 3; i++) {
    std_handles[i] = (HANDLE)_get_osfhandle(i);
    std_types[i] = GetFileType(std_handles[i]);
  }
#endif
  return Val_unit;
}

/* Check that the cached standard HANDLEs are still open and still refer to
   the same kind of object (a recycled HANDLE value would typically point to
   one of the temporary capture files instead). */
CAMLprim value out_channel_redirect_std_handles_valid(value unit){
#ifdef _WIN32
  int i;
  DWORD flags;
  for (i = 0; i < 3; i++) {
    if (std_handles[i] == INVALID_HANDLE_VALUE) continue;
    if (!GetHandleInformation(std_handles[i], &flags)) return Val_false;
    if (GetFileType(std_handles[i]) != std_types[i]) return Val_false;
  }
#endif
  return Val_true;
}

CAMLprim value out_channel_redirect_print_stdout(value unit){
  fprintf(stdout, "stdout from external");
  fflush(stdout);
  return Val_unit;
}

CAMLprim value out_channel_redirect_print_stderr(value unit){
  fprintf(stderr, "stderr from external");
  fflush(stderr);
  return Val_unit;
}


