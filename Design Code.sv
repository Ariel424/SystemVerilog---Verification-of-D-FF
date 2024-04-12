Moudle DFF (DFF_IF Vif); 

Always @(posedge vif.clk)
begin 
  if (vif.rst == 1'b1)
    vif.dout <= 1'b0; 
  else 
    vif.dout <= vif.din;
 end
endmodule 

interface dff_if; 
  logic Clk; 
  logic Rst; 
  logic Din; 
  logic Dout; 

endinterface 
