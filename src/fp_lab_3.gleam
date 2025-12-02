import argv
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import glint
import glint/constraint

import input_parser
import lagrange
import linear
import messages
import newton
import output

fn create_step_flag() {
  glint.float_flag("step")
  |> glint.flag_default(0.5)
  |> glint.flag_help("Defines step between generated X values to interpolate")
}

fn create_points_num_flag() {
  glint.int_flag("n")
  |> glint.flag_default(4)
  |> glint.flag_help(
    "Defines number of point needed for Lagrange and Newton algorithms to interpolate",
  )
}

fn create_algos_flag() {
  glint.strings_flag("algos")
  |> glint.flag_default(["linear"])
  |> glint.flag_help("Defines set of algoritms to use for interpolation")
  |> glint.flag_constraint(
    ["linear", "lagrange", "newton"]
    |> constraint.one_of
    |> constraint.each,
  )
}

fn start() {
  use <- glint.command_help("Prints Hello, <NAME>!")

  use step <- glint.flag(create_step_flag())
  use n <- glint.flag(create_points_num_flag())
  use algos <- glint.flag(create_algos_flag())

  use _, _args, flags <- glint.command()

  let assert Ok(step) = step(flags)
  let assert Ok(n) = n(flags)
  let assert Ok(algos) = algos(flags)

  io.println("> Using n=" <> int.to_string(n))
  io.println("> Using step=" <> float.to_string(step))
  io.println("> Using alogos=" <> algos_to_str(algos, ""))

  let output_subj = create_ouput()

  let alg_subjects = list.map(algos, choose_and_spawn_algo(_, step, n))

  input_parser.start_input(alg_subjects, output_subj)
}

fn algos_to_str(a: List(String), acc: String) {
  case a {
    [head, ..tail] ->
      algos_to_str(tail, case acc {
        "" -> head
        _ -> acc <> "," <> head
      })
    _ -> acc
  }
}

fn create_ouput() {
  let this_subj: process.Subject(process.Subject(messages.OuptputMassage)) =
    process.new_subject()
  process.spawn(output.spawn_output(this_subj))
  process.receive_forever(this_subj)
}

fn choose_and_spawn_algo(
  alog_str: String,
  step: Float,
  n: Int,
) -> process.Subject(messages.InputMessage) {
  let this_subj: process.Subject(process.Subject(messages.InputMessage)) =
    process.new_subject()

  case alog_str {
    "linear" -> process.spawn(linear.spawn_linear(this_subj, step))
    "lagrange" -> process.spawn(lagrange.spawn_lagrange(this_subj, step, n))
    "newton" -> process.spawn(newton.spawn_newton(this_subj, step, n))
    _ -> {
      io.println_error("Unknown algorithm" <> alog_str)
      panic
    }
  }

  process.receive_forever(this_subj)
}

pub fn main() -> Nil {
  glint.new()
  |> glint.with_name("fp-lab-3")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: start())
  |> glint.run(argv.load().arguments)
}
