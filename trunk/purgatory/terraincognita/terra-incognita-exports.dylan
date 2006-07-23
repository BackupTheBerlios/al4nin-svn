synopsis: ICFP 2006 contest submission
author: heisenbug, Seth Taylor
copyright: © 2006 terraincognita team
module: dylan-user

define library terra-incognita
  use dylan;
  use common-dylan;
  use system;
  use io;
end library;

define module terra-incognita
  use common-dylan;
  use format-out;
  use standard-io;
  use file-system;
  use streams;
  use machine-words;
  use system, import: {<raw-pointer>, call-out, c-local-decl, c-expr};
  use Extensions, exclude: {main};
  use Introspection;
end module;
