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

  task run();
      repeat(count) begin
      assert(tr.randomize) else $error("[GEN] : RANDOMIZATION FAILED");
      mbx.put(tr.copy); 
      mbxref.put(tr.copy); 
      tr.display("GEN"); 
      @(sconext);
    end
    ->done; 
  endtask
  
endclass

class driver;
  transaction tr; 
  mailbox (transaction) mbx; 
  virtual dff_if vif;

  function new (mailbox #(transaction) mbx); 
  this.mbx = mbx; 
  endfunction 

    task reset();
    vif.rst <= 1'b1; 
    repeat(5) @(posedge vif.clk); 
    vif.rst <= 1'b0; 
    @(posedge vif.clk); 
    $display("[DRV] : RESET DONE"); 
  endtask

  task run(); 
    forever begin 
      mbx.get(tr);
      vif.din<=tr.din;
      @(posedge vif.clk); 
      tr.display("DRV"); 
      vif.din <= 1'b0; 
      @(posedge vif.clk); 
    end
  endtask
  
endclass

class monitor 

  transaction tr; 
  mailbox #(transaction) mbx;
  virtual dff_if vif;

  function new (mailbox #(transaction) mbx); 
    this.mbx = mbx; 
  endfunctio
  task run();
    tr = new(); 
    forever begin
      repeat (2) @(posedge vif.clk); 
      tr.dout = vif.dout; 
      mbx.put(tr);
      tr.display("MON"); 
      end
  endtask
endclass

class scoreboard 
  transaction tr; 
  transaction trref; // Define a reference transaction object for comparison
  mailbox #(transaction) mbx; // Create a mailbox to receive data from the driver
  mailbox #(transaction) mbxref; // Create a mailbox to receive reference data from the generator
  event sconext; // Event to signal completion of scoreboard work
 
  function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx; // Initialize the mailbox for receiving data from the driver
    this.mbxref = mbxref; // Initialize the mailbox for receiving reference data from the generator
  endfunction
  
  task run();
    forever begin
      mbx.get(tr); // Get a transaction from the driver
      mbxref.get(trref); // Get a reference transaction from the generator
      tr.display("SCO"); 
      trref.display("REF");

      if (tr.dout == trref.din)
        $display ("[SCO]: Data matched");
      else 
        $display ("[SCO]: The data dosen't match");
      $display ("End simulation");
      ->sconext; // Signal completion of scoreboard work
    end 
  endtask
endclass 

class environment; 
  generator gen; 
  driver drv; 
  monitor mox;
  scoreboard sco; 
  event next; // Event to signal communication between generator and scoreboard

  mailbox #(transaction) gdmbx; // Mailbox for communication between generator and driver
  mailbox #(transaction) msmbx; // Mailbox for communication between monitor and scoreboard
  mailbox #(transaction) mbxref; // Mailbox for communication between generator and scoreboard

  virtual dff_if vif;

  function new (virtual dff_if vif);
    gdmbx = new();
    mbxref = new(); 
    gen = new (gdmbx, mbxref);
    drv = new (gdmbx); 
    msmbx = new();
    mon = new (msmbx); 
    sco = new (msmbx, mbxref);
    this.vif = vif; 
    drv.vif = this.vif; // Connect the virtual interface to the driver
    mon.vif = this.vif; // Connect the virtual interface to the monitor
    gen.sconext = next; // Set the communication event between generator and scoreboard
    sco.sconext = next; // Set the communication event between scoreboard and generator
  endfunction 

  task pre_test (); 
    drv.reset(); // Perform the driver reset 
  endtask 

  task test (); 
    fork 
      gen.run(); 
      drv.rum(); 
      mon.run(); 
      sco.run(); 
    join_any 
  endtask 

  task post_test(); 
    wait (gen.done.trigger); //Wait for generator to complete 
    $finish(); // Finish simulation 
  endtask 

  task run(); 
    pre_test(); 
    test(); 
    post_test(); 
  endtask 
endclass

moudle tb; 
    dff_if vif(); 
    dff dut(vif);

    initial begin
      vif.clk <= 0; 
    end

    always #10 vif.clk <= ~vif.clk; 
    environment env;

    initial begin 
      env = new(vif);
      env.gen.count = 30;
      env.run();
    end 

    initial begin 
      $dumpfile ("dump.vcd"); 
      $dumpvars; 
    end
    endmodule 
