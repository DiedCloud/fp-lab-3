import gens/lazy
import gens/stream
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

import messages.{EOF, NextX}

pub fn spawn_generator(
  creator_subj: process.Subject(process.Subject(messages.GeneratorMessage)),
  step: Float,
) {
  fn() {
    let this_subj = process.new_subject()

    process.send(creator_subj, this_subj)

    loop(None, step, this_subj)
  }
}

fn loop(
  start_x: Option(Float),
  step: Float,
  this_subj: process.Subject(messages.GeneratorMessage),
) {
  let message = process.receive_forever(this_subj)

  case message {
    NextX(reply_to, init_start_x, end_x) -> {
      let real_start_x = case start_x {
        None -> init_start_x
        Some(s) -> s
      }

      let xs_list = get_list(real_start_x, step, end_x)
      process.send(reply_to, xs_list)

      let new_start_x = case list.last(xs_list) {
        Ok(val) -> val +. step
        Error(_) -> real_start_x
      }
      loop(Some(new_start_x), step, this_subj)
    }
    EOF -> Nil
  }
}

fn get_list(start_x: Float, step: Float, end_x: Float) -> List(Float) {
  lazy.new()
  |> lazy.map(fn(a: Int) { int.to_float(a) *. step })
  |> lazy.map(fn(a: Float) { a +. start_x })
  |> stream.from_lazy_list
  |> stream.while(fn(a) { a <. end_x })
}
