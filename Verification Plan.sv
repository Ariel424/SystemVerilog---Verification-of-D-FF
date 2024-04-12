class transaction; 

  rand bit Din; 
  bit Dout; 

  function transaction copy(); 
    copy = new(); 
    copy.din = this.din; 
    copy.dout = this.dout; 
  endfunction

  function void display (input string tag);
    $display("[%0s] : DIN : %0b DOUT : %0b", tag, din, dout);
  endfunction 

endclass

class generator; 

  transaction tr; 
  mailbox #(transaction) mbx;
  mailbox #(transaction) mbxref; 
  event sconext; 
  event done; 
  int count = 0;

   function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;  
    this.mbxref = mbxref;
    tr = new(); 
  endfunction
  
  
  
