import gens/lazy
import gleam/erlang/process
import gleam/list
import util

import messages.{type GeneratorMessage, type Point, InputEOF, NextPoint, Point}
import x_generator

pub fn spawn_newton(
  creator_subj: process.Subject(process.Subject(messages.InputMessage)),
  step: Float,
  n: Int,
) {
  fn() {
    let this_subj: process.Subject(process.Subject(messages.GeneratorMessage)) =
      process.new_subject()
    process.spawn(x_generator.spawn_generator(this_subj, step))
    let generator_subj = process.receive_forever(this_subj)

    let this_subj: process.Subject(messages.InputMessage) =
      process.new_subject()
    process.send(creator_subj, this_subj)

    loop(generator_subj, [], this_subj, n)
  }
}

fn loop(
  generator_subj: process.Subject(GeneratorMessage),
  known: List(Point),
  this_subj: process.Subject(messages.InputMessage),
  n: Int,
) {
  let message = this_subj |> process.receive_forever()

  case message {
    NextPoint(Point(x, _y) as cur_point, output_subj) ->
      case list.length(known) == n - 1 {
        True -> {
          let xs_list =
            process.call_forever(generator_subj, messages.NextX(
              _,
              util.unsafe_list_at(known, 0).x,
              x,
            ))
          let res_list = list.map(xs_list, newton_interpolate(known, _))

          process.send(output_subj, messages.Result("Newton", res_list))

          let next_known = case known {
            [_to_drop, ..tail] -> list.append(tail, [cur_point])
            _ -> panic
          }

          loop(generator_subj, next_known, this_subj, n)
        }
        False ->
          loop(generator_subj, list.append(known, [cur_point]), this_subj, n)
      }

    InputEOF -> process.send(generator_subj, messages.EOF)
  }
}

pub fn newton_interpolate(points: List(Point), x: Float) {
  let #(xs, ys) = points |> list.map(fn(p) { #(p.x, p.y) }) |> list.unzip

  let y =
    list.fold(
      // от 1 до lenth-1
      lazy.new() |> lazy.map(fn(a) { a + 1 }) |> lazy.take(list.length(xs) - 1),
      case ys {
        [s, ..] -> s
        _ -> panic
      },
      fn(acc, k) {
        acc +. calc_y_delta_divided(k, 0, xs, ys) *. calc_t(k, x, xs)
      },
    )
  Point(x, y)
}

// k=0: 1; k=1: (x-x_0); k=2: (x-x_0)(x-x_1)
fn calc_t(k: Int, x: Float, xs: List(Float)) -> Float {
  list.fold(lazy.new() |> lazy.take(k), 1.0, fn(acc, i) {
    acc *. { x -. util.unsafe_list_at(xs, i) }
  })
}

fn calc_y_delta_divided(
  k: Int,
  i: Int,
  xs: List(Float),
  ys: List(Float),
) -> Float {
  case k <= 0 {
    True -> util.unsafe_list_at(ys, i)
    False ->
      {
        calc_y_delta_divided(k - 1, i + 1, xs, ys)
        -. calc_y_delta_divided(k - 1, i, xs, ys)
      }
      /. { util.unsafe_list_at(xs, i + k) -. util.unsafe_list_at(xs, i) }
  }
}
