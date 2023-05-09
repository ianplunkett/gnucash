{
  "targets": [
    {
      "target_name": "gnucash_core",
      "sources": [
        "bindings/python/gnucash_core_wrap.cxx"
      ],
      "include_dirs": [
        "../gnucash-build/common",
        "./libgnucash/engine",
        "/usr/include/glib-2.0",
        "/usr/lib/aarch64-linux-gnu/glib-2.0/include",
        "./libgnucash/core-utils",
        "./libgnucash/app-utils"
      ]
    }
  ]
}
