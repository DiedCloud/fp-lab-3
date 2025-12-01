import gens/lazy
import gens/stream
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/result

import messages.{EOF, NextX}

pub fn spawn_generator(
  creator_subj: process.Subject(process.Subject(messages.GeneratorMessage)),
) {
  fn() {
    let this_subj = process.new_subject()

    process.send(creator_subj, this_subj)

    loop(0.0, this_subj)
  }
}

fn loop(start_x: Float, this_subj: process.Subject(messages.GeneratorMessage)) {
  let message = process.receive_forever(this_subj)

  case message {
    NextX(reply_to, end_x, step) -> {
      let xs_list = get_list(start_x, step, end_x)
      let new_start_x = { list.last(xs_list) |> result.unwrap(start_x) } +. step
      process.send(reply_to, xs_list)

      loop(new_start_x, this_subj)
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
