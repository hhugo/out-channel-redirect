(module
   (type $bytes (array (mut i8)))

   (import "env" "caml_ml_output"
      (func $caml_ml_output
         (param (ref eq)) (param (ref eq)) (param (ref eq)) (param (ref eq))
         (result (ref eq))))
   (import "env" "caml_ml_flush"
      (func $caml_ml_flush (param (ref eq)) (result (ref eq))))

   (global $stdout_chan (mut (ref null eq)) (ref.null eq))
   (global $stderr_chan (mut (ref null eq)) (ref.null eq))

   (data $stdout_msg "stdout from external")
   (data $stderr_msg "stderr from external")

   (func (export "out_channel_redirect_init_channels")
      (param $stdout (ref eq)) (param $stderr (ref eq)) (result (ref eq))
      (global.set $stdout_chan (local.get $stdout))
      (global.set $stderr_chan (local.get $stderr))
      (ref.i31 (i32.const 0)))

   (func $write_to_channel
      (param $chan (ref eq)) (param $bytes (ref eq))
      (drop (call $caml_ml_output
         (local.get $chan)
         (local.get $bytes)
         (ref.i31 (i32.const 0))
         (ref.i31 (array.len (ref.cast (ref $bytes) (local.get $bytes))))))
      (drop (call $caml_ml_flush (local.get $chan))))

   (func (export "out_channel_redirect_print_stdout")
      (param (ref eq)) (result (ref eq))
      (if (i32.eqz (ref.is_null (global.get $stdout_chan)))
         (then
            (call $write_to_channel
               (ref.as_non_null (global.get $stdout_chan))
               (array.new_data $bytes $stdout_msg
                  (i32.const 0) (i32.const 20)))))
      (ref.i31 (i32.const 0)))

   (func (export "out_channel_redirect_print_stderr")
      (param (ref eq)) (result (ref eq))
      (if (i32.eqz (ref.is_null (global.get $stderr_chan)))
         (then
            (call $write_to_channel
               (ref.as_non_null (global.get $stderr_chan))
               (array.new_data $bytes $stderr_msg
                  (i32.const 0) (i32.const 20)))))
      (ref.i31 (i32.const 0)))

   (func (export "out_channel_redirect_std_handles_valid")
      (param (ref eq)) (result (ref eq))
      (ref.i31 (i32.const 1)))
)
