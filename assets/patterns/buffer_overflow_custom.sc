// Custom buffer overflow pattern for specific scenarios

// Pattern: Array access without bounds check
val arrayAccess = cpg.identifier.name(".*buffer.*|.*data.*").where { id =>
  id.next.isCall.name("\\[\\]") &&
  !id.next.inAst.isCall.nameAny("size", "length", "len", "count")
}

// Pattern: Large stack allocation
val largeStack = cpg.identifier.where(_.typeFullName("char\\[.*\\]")).where { id =>
  id.typeFullName.matches(".*\\[[1-9][0-9]{2,}\\].*")  // Arrays > 100 bytes
}

// Pattern: Unsafe cast from size_t to int
val unsafeCast = cpg.call.name("int.*|short.*").where { call =>
  call.argument(0).inCall.name("sizeof|strlen|size").exists
}
