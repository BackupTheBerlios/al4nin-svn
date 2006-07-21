synopsis: ICFP 2006 contest submission
author: heisenbug
copyright: © 2006 terraincognita team
module: dylan-user

define library terra-incognita
  use dylan;
  use common-dylan;
  use io;
//  use Extensions;
end library;

define module terra-incognita
  use common-dylan;
  use format-out;
  use standard-io;
  use streams;
  use Extensions, exclude: {main};
end module;
