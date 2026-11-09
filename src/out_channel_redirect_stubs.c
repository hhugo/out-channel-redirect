#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <unistd.h>
#ifdef _WIN32
#include <windows.h>
#include <io.h>
#endif

/* duplicated from caml/sys.h and io.c */
CAMLextern value caml_channel_descriptor(value vchannel);
#define NO_ARG Val_int(0)
CAMLextern void caml_sys_error (value);
/* End of code duplication */

#ifdef _WIN32
/* On Windows, [dup2] closes the HANDLE previously attached to the target
   CRT fd. The HANDLEs initially attached to fds 0, 1 and 2 are cached
   elsewhere (e.g. [Unix.stdin], [Unix.stdout] and [Unix.stderr]), so closing
   them leaves those dangling, or pointing at an unrelated object once the
   HANDLE value gets reused. We protect them from being closed: they stay
   valid and keep referring to the original standard streams. */
static HANDLE std_handles[3];
static int std_handles_initialized = 0;

static void init_std_handles(void) {
  int i;
  if (std_handles_initialized) return;
  for (i = 0; i < 3; i++) std_handles[i] = (HANDLE)_get_osfhandle(i);
  std_handles_initialized = 1;
}

static int redirect_fd(int src, int dst) {
  HANDLE h;
  int protect, ret;
  init_std_handles();
  h = (HANDLE)_get_osfhandle(dst);
  protect = dst >= 0 && dst < 3 && h != INVALID_HANDLE_VALUE
    && h == std_handles[dst]
    && SetHandleInformation(h, HANDLE_FLAG_PROTECT_FROM_CLOSE,
                            HANDLE_FLAG_PROTECT_FROM_CLOSE);
  ret = dup2(src, dst);
  if (protect) SetHandleInformation(h, HANDLE_FLAG_PROTECT_FROM_CLOSE, 0);
  return ret;
}
#else
#define redirect_fd dup2
#endif

CAMLprim value out_channel_redirect_setup (value voutput, value vtocapture) {
  int output_fd, tocapture_fd, fd, ret;
  tocapture_fd = Int_val(caml_channel_descriptor(vtocapture));
  output_fd = Int_val(caml_channel_descriptor(voutput));
  fd = dup(tocapture_fd);
  if(fd == -1) caml_sys_error(NO_ARG);
  ret = redirect_fd(output_fd, tocapture_fd);
  if(ret == -1) caml_sys_error(NO_ARG);
  return Val_int(fd);
}

CAMLprim value out_channel_redirect_restore (value vcaptured, value vold) {
  int captured_fd, ret;
  int old = Int_val(vold);
  captured_fd = Int_val(caml_channel_descriptor(vcaptured));
  ret = redirect_fd(old, captured_fd);
  if(ret == -1) caml_sys_error(NO_ARG);
  ret = close(old);
  if(ret == -1) caml_sys_error(NO_ARG);
  return Val_unit;
}
