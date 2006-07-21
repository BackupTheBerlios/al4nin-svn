module: terra-incognita
synopsis: ICFP 2006 contest submission
author: Seth Taylor, heisenbug
copyright: © 2006 terraincognita team

define function load-codex(fn :: <string>) => (scroll :: <scroll>)
  let codex = make(<scroll>, size: 0);
  block (return)
    with-open-file(fs = fn, element-type: <integer>)
      read-to-end(fs);
      while (#t)
        let value = read-element(fs, on-end-of-stream: #f);
        unless (value) return(codex) end;
        add!(codex, value);
      end while;
    end with-open-file;
  end block;
end function load-codex;


