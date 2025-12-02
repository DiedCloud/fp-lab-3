pub fn unsafe_list_at(l: List(a), index: Int) -> a {
  case l {
    [head, ..tail] ->
      case index <= 0 {
        True -> head
        False -> unsafe_list_at(tail, index - 1)
      }
    _ -> panic
  }
}
