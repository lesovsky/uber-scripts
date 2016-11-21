portage-utils

qfile <filename>        -- what package filename belongs.
qsize <pkg>             -- get size used by pkg.
quse -D <useflag>       -- describe USE flag
qlop -l                 -- list merge history (based on emerge.log), helps to answer when pkg was installed
qlop -u                 -- list unmerge history (based on emerge.log), helps to answer when pkg was uninstalled
qcheck                  -- check pks and its content
qsearch <pattern>       -- search pkgs using pattern
qsearch -S <pattern>    -- search pkgs with pattern in its descriptions
qdepends <pkg>          -- show pkg DEPENDS
qdepends -r <pkg>       -- show pkg RDEPENDS
qlist -ISUv             -- list installed pks its versions, slots and use-flags.
qlist <pkg>             -- list pkg content

equery depends <pkg>    -- list packages which depend on specified <pkg>
equery hasuse <flag>    -- list installed pkgs with specified USE flag.
equery meta <pkg>       -- show metadata for <pkg>.
equery uses <pkg>       -- show USE flags for specified <pkg> and its descriptions.
