module: terra-incognita
synopsis: ICFP 2006 contest submission
author: Seth Taylor
copyright: © 2006 terraincognita team

define function load-codex(fn :: <string>) => (<object>)
  // let codex = make(<stretchy-vector>, size: 0);
  with-open-file(fs = "codex.umz", element-type: <integer>)
    read-to-end(fs)
    /* while (#t)
      let value = read-element(fs, on-end-of-stream: #f);
      unless (value) return() end;
      add!(codex, value);
    end*/
  end;
end function load-codex;


