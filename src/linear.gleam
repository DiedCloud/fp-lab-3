import gleam/erlang/process
import gleam/list
import gleam/option.{type Option, None, Some}
import messages.{type GeneratorMessage, type Point, InputEOF, NextPoint, Point}
import x_generator

pub fn spawn_linear(
  creator_subj: process.Subject(process.Subject(messages.InputMessage)),
) {
  fn() {
    let this_subj: process.Subject(process.Subject(messages.GeneratorMessage)) =
      process.new_subject()
    process.spawn(x_generator.spawn_generator(this_subj))
    let generator_subj = process.receive_forever(this_subj)

    let this_subj: process.Subject(messages.InputMessage) =
      process.new_subject()
    process.send(creator_subj, this_subj)

    loop(generator_subj, None, this_subj)
  }
}

fn loop(
  generator_subj: process.Subject(GeneratorMessage),
  prev: Option(Point),
  this_subj: process.Subject(messages.InputMessage),
) {
  let message = this_subj |> process.receive_forever()

  case message {
    NextPoint(Point(x, _y) as cur_point, step, output_subj) ->
      case prev {
        Some(prev_point) -> {
          let xs_list =
            process.call_forever(generator_subj, messages.NextX(_, x, step))
          let res_list =
            list.map(xs_list, linear_interpolate(prev_point, cur_point, _))

          process.send(output_subj, messages.Result("Linear", res_list))

          loop(generator_subj, Some(cur_point), this_subj)
        }
        None -> loop(generator_subj, Some(cur_point), this_subj)
      }

    InputEOF -> process.send(generator_subj, messages.EOF)
  }
}

pub fn linear_interpolate(a: Point, b: Point, x: Float) {
  let y = { a.y *. { b.x -. x } +. b.y *. { x -. a.x } } /. { b.x -. a.x }
  Point(x, y)
}
