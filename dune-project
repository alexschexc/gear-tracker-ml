(lang dune 3.20)

(name gearTracker-ml)

(generate_opam_files true)

(source
 (github username/gearTracker-ml))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name gearTracker-ml)
 (synopsis "Firearms and gear tracking application - OCaml port")
 (description "Offline desktop application for tracking firearms, gear, reloads, and related activities")
 (depends
  ocaml
  dune
  sqlite3
  ptime
  uuidm
  csv))
