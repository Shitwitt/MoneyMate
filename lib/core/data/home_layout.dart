/// Reorders the visible cards without moving or resurrecting hidden cards.
/// [newIndex] follows Flutter's ReorderableListView insertion-index convention.
List<String> reorderVisibleHomeCards(
  List<String> current,
  List<String> visible,
  int oldIndex,
  int newIndex,
) {
  final visibleSet = visible.toSet();
  if (visibleSet.length != visible.length ||
      current.toSet().length != current.length ||
      !visibleSet.every(current.contains) ||
      oldIndex < 0 ||
      oldIndex >= visible.length ||
      newIndex < 0 ||
      newIndex > visible.length) {
    throw const FormatException('Home layout changed. Try the move again.');
  }
  final reordered = [...visible];
  final item = reordered.removeAt(oldIndex);
  reordered.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
  var next = 0;
  return [
    for (final id in current)
      if (visibleSet.contains(id)) reordered[next++] else id,
  ];
}
