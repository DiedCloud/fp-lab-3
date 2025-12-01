# Реализация множества на красно-чёрном дереве на Gleam

## Лабораторная работа #3

- **Преподаватель:** Пенской Александр Владимирович
- **Выполнил:** `Фролов Кирилл Дмитриевич`, `367590`
- ИТМО, Санкт-Петербург, 2025

## Описание работы

Данная лабораторная работа направлена на получение навыков работы с вводом/выводом,
потоковой обработкой данных, командной строкой.

## Требования

В рамках лабораторной работы предлагается повторно реализовать лабораторную работу по предмету
"Вычислительная математика" посвящённую интерполяции (лабораторная работа 5) со следующими дополнениями:

- обязательно должна быть реализована линейная интерполяция
(отрезками, [link](https://en.wikipedia.org/wiki/Linear_interpolation));
- настройки алгоритма интерполяции и выводимых данных должны задаваться через аргументы командной строки:
   - какие алгоритмы использовать (в том числе два сразу);
   - частота дискретизации результирующих данных;
   - и т.п.;
- входные данные должны задаваться в текстовом формате на подобии ".csv" (к примеру `x;y\n` или `x\ty\n`)
и подаваться на стандартный ввод, входные данные должны быть отсортированы по возрастанию x;
- выходные данные должны подаваться на стандартный вывод;
- программа должна работать в потоковом режиме (пример -- `cat | grep 11`), это значит,
что при запуске программы она должна ожидать получения данных на стандартный ввод,
и, по мере получения достаточного количества данных, должна выводить рассчитанные точки в стандартный вывод;

Приложение должно быть организовано следующим образом:

```text
    +---------------------------+
    | обработка входного потока |
    +---------------------------+
            |
            | поток / список / последовательность точек
            v
    +-----------------------+      +------------------------------+
    | алгоритм интерполяции |<-----| генератор точек, для которых |
    +-----------------------+      | необходимо вычислить         |
            |                      | промежуточные значения       |
            |                      +------------------------------+
            |
            | поток / список / последовательность рассчитанных точек
            v
    +------------------------+
    | печать выходных данных |
    +------------------------+
```

Потоковый режим для алгоритмов, работающих с группой точек должен работать следующим образом:

```text
o o o o o o . . x x x
  x x x . . o . . x x x
    x x x . . o . . x x x
      x x x . . o . . x x x
        x x x . . o . . x x x
          x x x . . o . . x x x
            x x x . . o o o o o o EOF
```

где:

- каждая строка -- окно данных, на основании которых производится расчёт алгоритма;
- строки сменяются по мере поступления в систему новых данных (старые данные удаляются из окна, новые -- добавляются);
- `o` -- рассчитанные данные, можно видеть:
   - большинство окон используется для расчёта всего одной точки, так как именно в "центре" результат наиболее точен;
   - первое и последнее окно используются для расчёта большого количества точек, так лучших данных для расчёта у нас не будет.
- `.` -- точки, задействованные в рассчете значения `o`.
- `x` -- точки, расчёт которых для "окон" не требуется.

Пример вычислений (`my_lab3 --linear --step 0.7`, `<` -- ввод, `>` -- вывод):

```text
< 0 0
< 1 1
> linear: 0 0
> linear: 0.7 0.7
< 2 2
> linear: 1.4 1.4
> 3 3
> linear: 2.1.4 2.1
> linear: 2.8 2.8
< EOF
> linear: 2.8 2.8
```

`my_lab3 --newton -n 4 --step 0.5` (интерполяция по 4 точкам):

```text
< 0 0
< 1 1
< 2 2
> 3 3
> 4 4
> newton: 0 0
> newton: 0.5 0.5
> newton: 1 1
> newton: 1.5 1.5
> newton: 2 2
> newton: 2.5 2.5
> newton: 3 3
< 5 5
> newton: 3.5 3.5
> newton: 4 4
< 7 7
> newton: 4.5 4.5
> newton: 5 5
< 8 8
> newton: 5.5 5.5
> newton: 6 6
> newton: 6.5 6.5
> newton: 7 7
< EOF
> newton: 7.5
> newton: 8
```

Общие требования:

- программа должна быть реализована в функциональном стиле;
- ввод/вывод должен быть отделён от алгоритмов интерполяции;
- требуется использовать идиоматичный для технологии стиль программирования.


## Реализация

Обрабатываем команду запуска, разбираем аргументы

```gleam
fn create_step_flag() {
  glint.float_flag("step")
  |> glint.flag_default(0.5)
  |> glint.flag_help("Defines step between generated X values to interpolate")
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
  use algos <- glint.flag(create_algos_flag())

  use _, _args, flags <- glint.command()

  let assert Ok(step) = step(flags)
  let assert Ok(algos) = algos(flags)

  io.println("> Using step=" <> float.to_string(step))
  io.println("> Using alogos=" <> algos_to_str(algos, ""))

  //...
}

pub fn main() -> Nil {
  glint.new()
  |> glint.with_name("fp-lab-3")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: start())
  |> glint.run(argv.load().arguments)
}
```

Spawn-им процесс вывода, который:
- Принимает сообщение с методом с посчитанными точками
- Печатает их
- Вызывает сам себя (<=> встаёт на приём)
 
```gleam
fn create_ouput() {
  let this_subj: process.Subject(process.Subject(messages.OuptputMassage)) =
    process.new_subject()
  process.spawn(output.spawn_output(this_subj))
  process.receive_forever(this_subj)
}
```

```gleam
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
```

Spawn-им на каждый алгоритм процесс, который:
 - Spawn-ит процесс генератора под себя
 - Принимает точку
 - Просит процесс генератора набор точек для интерполирования
 - Считает интерполированные значения
 - Отправляет ответ на вывод
 - Вызывает сам себя

```gleam
fn choose_and_spawn_algo(
  alog_str: String,
) -> process.Subject(messages.InputMessage) {
  let this_subj: process.Subject(process.Subject(messages.InputMessage)) =
    process.new_subject()

  case alog_str {
    "linear" -> process.spawn(linear.spawn_linear(this_subj))
    "lagrange" -> process.spawn(lagrange.spawn_lagrange(this_subj))
    "newton" -> process.spawn(newton.spawn_newton(this_subj))
    _ -> {
      io.println_error("Unknown algorithm" <> alog_str)
      panic
    }
  }

  process.receive_forever(this_subj)
}
```

```gleam
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

fn linear_interpolate(a: Point, b: Point, x: Float) {
  let y = { a.y *. { b.x -. x } +. b.y *. { x -. a.x } } /. { b.x -. a.x }
  Point(x, y)
}
```

Процесс генератора:
 - Принимает точку X, до которой нужно сгенерировать последовательность X для интерполяции
 - Генерирует последовательность и отправляет её процессу алгоритма
 - Вызывает сам себя, передавая в начальную точку значение последней

```gleam
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
```

Переходим к вводу в основном процессе:
- Принимаем точку (проверяя валидность ввода)
- Отправляем эту точку в каждый из созданных алгоритмов
- Вызываем сами себя

```gleam
pub fn start_input(
  step: Float,
  alg_subjects: List(process.Subject(InputMessage)),
  output_subj: process.Subject(OuptputMassage),
) {
  io.println("Enter lines with two floats separated by space (Ctrl+D to exit):")
  loop(step, alg_subjects, output_subj)
}

fn loop(
  step: Float,
  alg_subjects: List(process.Subject(InputMessage)),
  output_subj: process.Subject(OuptputMassage),
) {
  let inp_res = input.input("")
  case inp_res {
    Ok(line) -> {
      case string.split(line, " ") {
        [x, y] -> {
          let x = case float.parse(x), int.parse(x) {
            Ok(x), _ -> Ok(x)
            _, Ok(x) -> Ok(int.to_float(x))
            _, _ -> Error(Nil)
          }

          let y = case float.parse(y), int.parse(y) {
            Ok(y), _ -> Ok(y)
            _, Ok(y) -> Ok(int.to_float(y))
            _, _ -> Error(Nil)
          }

          case x, y {
            Ok(x), Ok(y) -> {
              list.map(alg_subjects, process.send(
                _,
                messages.NextPoint(messages.Point(x, y), step, output_subj),
              ))
              Nil
            }
            _, _ -> io.println("You should input to numbers splitted by space")
          }
        }
        _ -> io.println("You should input to numbers splitted by space")
      }
      loop(step, alg_subjects, output_subj)
    }
    Error(_) -> io.println("Failed to read line")
  }
}
```

## Ввод/вывод программы

`gleam run -- --step=1.5 --algos=linear,lagrange,newton`
```text
PS G:\Files\Itmo\FP\fp-lab-3> gleam run -- --step=1.5 --algos=linear,lagrange,newton
   Compiled in 0.06s
    Running fp_lab_3.main
> Using step=1.5
> Using alogos=linear,lagrange,newton
Enter lines with two floats separated by space (Ctrl+D to exit):
1 1
2 2
> Linear: 0.0 0.0
> Linear: 1.5 1.5
> Lagrange: 0.0 1.0
> Lagrange: 1.5 1.0
> Newton: 0.0 1.0
> Newton: 1.5 1.0
5 5
> Linear: 3.0 3.0
> Linear: 4.5 4.5
> Newton: 3.0 3.0
> Newton: 4.5 4.5
> Lagrange: 3.0 3.0
> Lagrange: 4.5 4.5
7 7
> Linear: 6.0 6.0
> Lagrange: 6.0 6.0
> Newton: 6.0 6.0
9 9
> Linear: 7.5 7.5
> Lagrange: 7.5 7.499999999999999
> Newton: 7.5 7.5
10 10
> Linear: 9.0 9.0
> Lagrange: 9.0 9.0
> Newton: 9.0 9.0
```

## Запуск тестов

Для запуска тестов с использованием gleam:
```bash
gleam test
```

Результат запуска тестов:
```
PS G:\Files\Itmo\FP\fp-lab-3> gleam test
  Compiling fp_lab_3
   Compiled in 0.40s
    Running fp_lab_3_test.main
...
3 passed, no failures
```

## Заключение

В ходе выполнения лабораторной работы реализованы 3 алгоритма интерполяции - линейного, Лагранжа и Ньютона.

Разработанная программа получает данные со стандартного ввода.
Она использует отдельные легковесные процессы для:
 - интерполяции каждым алгоритмом,
 - генерации последовательности точек для каждого алгоритма,
 - и ещё отдельный процесс для вывода.

Было интересной и непростой задачей настроить обмен сообщениями между процессами. 
Но именно через него алгоритмы получают введённые данные.

## Зависимости

Для сборки и запуска проекта использовались:

- gleam 1.13.0
- Erlang OTP 28.1
