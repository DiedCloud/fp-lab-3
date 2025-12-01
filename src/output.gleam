import gleam/erlang/process
import gleam/float
import gleam/io
import messages.{OutputEOF, Result}

pub fn spawn_output(
  creator_subj: process.Subject(process.Subject(messages.OuptputMassage)),
) {
  fn() {
    let this_subj: process.Subject(messages.OuptputMassage) =
      process.new_subject()
    process.send(creator_subj, this_subj)

    loop(this_subj)
  }
}

fn loop(this_subj: process.Subject(messages.OuptputMassage)) {
  let message = process.receive_forever(this_subj)
  case message {
    Result(method_name, points) -> {
      rec_print(method_name, points)
      loop(this_subj)
    }
    OutputEOF -> Nil
  }
}

fn rec_print(method_name: String, points: List(messages.Point)) {
  case points {
    [p, ..tail] -> {
      io.println(
        "> "
        <> method_name
        <> ": "
        <> float.to_string(p.x)
        <> " "
        <> float.to_string(p.y),
      )
      rec_print(method_name, tail)
    }
    _ -> Nil
  }
}
