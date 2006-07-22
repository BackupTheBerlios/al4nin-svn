module: terra-incognita
synopsis: ICFP 2006 contest submission
author: Seth Taylor, heisenbug
copyright: © 2006 terraincognita team

define function load-codex(fn :: <string>) => (scroll :: <scroll>)
  let codex = make(<scroll>, size: 586740);
  let at :: <integer> = 0;
  block (return)
    with-open-file (fs = fn, element-type: <byte-character>)
      while (#t)
        let obj = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <machine-word> = as(<machine-word>, as(<integer>, obj));
        let obj = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <machine-word> = u%+(u%shift-left(value, 8), as(<machine-word>, as(<integer>, obj)));
        let obj = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <machine-word> = u%+(u%shift-left(value, 8), as(<machine-word>, as(<integer>, obj)));
        let obj = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <machine-word> = u%+(u%shift-left(value, 8), as(<machine-word>, as(<integer>, obj)));
        codex[at] := value;
        at := at + 1;
      end while;
    end with-open-file;
  end block;
end function load-codex;


