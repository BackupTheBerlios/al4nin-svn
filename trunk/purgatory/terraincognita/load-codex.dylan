module: terra-incognita
synopsis: ICFP 2006 contest submission
author: Seth Taylor, heisenbug
copyright: © 2006 terraincognita team

define function load-codex(fn :: <string>) => (scroll :: <scroll>)
  let codex = make(<scroll>, size: 586740);
  let at = 0;
  block (return)
    with-open-file(fs = fn, element-type: <byte-character>)
//      read-to-end(fs);
      while (#t)
        let obj = read-element(fs, on-end-of-stream: #f);
//        format-out("read1: %s\n", obj);
        unless (obj) return(codex) end;
        let value :: <integer> = as(<integer>, obj);
        let obj = read-element(fs, on-end-of-stream: #f);
//        format-out("read2: %s\n", obj);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
        let obj = read-element(fs, on-end-of-stream: #f);
//        format-out("read3: %s\n", obj);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
        let obj = read-element(fs, on-end-of-stream: #f);
//        format-out("read4: %s\n", obj);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
//        add!(codex, value);
        codex[at] := value;
        at := at + 1;
//        format-out("added: %d\n", value);
      end while;
    end with-open-file;
  end block;
end function load-codex;


