--Process commnication: Ada lab part 3

with Ada.Calendar;
with Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;
use Ada.Calendar;
use Ada.Text_IO;

procedure comm1 is
    Message: constant String := "Process communication";
	type Buffer_Array is array (0 .. 9) of Integer;
	Gen: Ada.Numerics.Float_Random.Generator;
	Random_Delay: Float;

	subtype Random_Range is Integer range 1 .. 20;
	package R is new Ada.Numerics.Discrete_Random(Random_Range);

	Gen_Int: R.Generator;

	task buffer is
		entry Get(X: out Integer);
		entry Put(X: in Integer);
		entry Stop;
	end buffer;

	task producer is
		entry Stop;
	end producer;

	task consumer is
	end consumer;

	task body buffer is 
		Message: constant String := "buffer executing";
		Buffer: Buffer_Array := (0,0,0,0,0,0,0,0,0,0);
		Current_Position: Integer := -1;
	begin
		Put_Line(Message);
		loop
			select
				when Current_Position >= 0 =>
					accept Get(X: out Integer) do
						X := Buffer(Current_Position);
						Put_Line("Buffer returns value" & Integer'Image(X));
						Current_Position := Current_Position - 1;
					end Get;
			or
				when Current_Position < 9 =>
					accept Put(X: in Integer) do
						Put_Line("Buffer received value" & Integer'Image(X));
						Current_Position := Current_Position + 1;
						Buffer(Current_Position) := X;
					end Put;
			or
				accept Stop;
				Put_Line("Buffer received Stop signal");
				exit;
			end select;
		end loop;
		Put_Line("Buffer exiting");
	end buffer;

	task body producer is 
		Message: constant String := "producer executing";
		Value: Random_Range;
	begin
		Put_Line(Message);
		loop
			select
				accept Stop;
				Put_Line("Producer received Stop signal");
				exit;
			else
				R.Reset(Gen_Int);
				Value := R.Random(Gen_Int);
				Put_Line("Producer puts value: " & Integer'Image(Value));
				buffer.Put(Value);
				Ada.Numerics.Float_Random.Reset(Gen);
				Random_Delay := Ada.Numerics.Float_Random.Random(Gen);
				delay(Duration(Random_Delay));
			end select;
		end loop;
		Put_Line("Producer exiting");
	end producer;

	task body consumer is 
		Message: constant String := "consumer executing";
		Value: Integer;
		Sum: Integer := 0;
	begin
		Put_Line(Message);
		Main_Cycle:
		loop
			Put_Line("Consumer gets value");
			buffer.Get(Value);
			Put_Line("Consumer got value" & Integer'Image(Value));
			Sum := Sum + Value;

			if Sum > 100 then
				Put_Line("Sum greater than 100");
				exit Main_Cycle;
			end if;

			Ada.Numerics.Float_Random.Reset(Gen);
			Random_Delay := Ada.Numerics.Float_Random.Random(Gen);
			delay(Duration(Random_Delay));
		end loop Main_Cycle; 

		producer.Stop;
		buffer.Stop;
		Put_Line("Consumer exiting");
		exception
			when TASKING_ERROR =>
				Put_Line("Buffer finished before producer");
	end consumer;
begin
	Put_Line(Message);
end comm1;
