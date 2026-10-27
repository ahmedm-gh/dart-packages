/// Defines the search boundary when resolving dependencies across container hierarchies.
enum LookupScope {
  /// Resolves from this container first; if not found, cascades up through
  /// ancestors to the root container (standard lexical scope inheritance).
  inherited,

  /// Resolves strictly within this container (`this`), never traversing to parents.
  local,

  /// Resolves strictly within the immediate direct parent container, never cascading further.
  parent,

  /// Skips this container and resolves starting from the direct parent,
  /// cascading up through ancestors to root (decorator / "super" pattern).
  ancestors,

  /// Resolves directly from the root container, bypassing local and intermediate scopes.
  root,
}
