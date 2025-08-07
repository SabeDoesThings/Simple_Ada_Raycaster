with SDL.Events.Events;
with SDL.Events.Keyboards;
with SDL.Inputs.Keyboards;
with SDL.Timers; use SDL.Timers;
with SDL.Video.Palettes;
with SDL.Video.Renderers;
with SDL.Video.Renderers.Makers;
with SDL.Video.Windows;
with SDL.Video.Windows.Makers;
with Ada.Numerics; use Ada.Numerics;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

procedure Ada_Raycaster is
   Map_Width, Map_Height : constant Integer := 24;
   Screen_Width : constant Integer := 640;
   Screen_Height : constant Integer := 480;

   World_Map : array (1 .. Map_Width, 1 .. Map_Height) of Integer := (
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
      [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1],
      [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
   );

   Pos_X : Float := 22.0;
   Pos_Y : Float := 12.0;
   Dir_X : Float := -1.0;
   Dir_Y : Float := 0.0;
   Plane_X : Float := 0.0;
   Plane_Y : Float := 0.66;

   Time : Float := 0.0;
   Old_Time : Float := 0.0;

   Game_Win : SDL.Video.Windows.Window;
   Game_Ren : SDL.Video.Renderers.Renderer;
   Event : SDL.Events.Events.Events;
   Running : Boolean := True;
   Win_Size : constant SDL.Positive_Sizes := (SDL.Dimension (Screen_Width), SDL.Dimension (Screen_Height));

   Target_FPS : constant := 60.0;
   Milliseconds : constant := 1000.0;
   Frame_Target_Time : constant := Milliseconds / Target_FPS;
   Last_Frame_Time : SDL.Timers.Milliseconds;
   Delta_Time : Float := 0.0;
   Time_To_Wait : SDL.Timers.Milliseconds;

   Move_Speed : Float;
   Rot_Speed : Float;

   Keys : SDL.Inputs.Keyboards.Key_State_Access := SDL.Inputs.Keyboards.Get_State;

   function Dim_Color (Color : SDL.Video.Palettes.Colour) return SDL.Video.Palettes.Colour is
      use SDL.Video.Palettes;
   begin
      return (
         Red => Color.Red / 2,
         Green => Color.Green / 2,
         Blue => Color.Blue / 2,
         Alpha => 255
      );
   end Dim_Color;

   procedure Ver_Line (
      Renderer : in out SDL.Video.Renderers.Renderer;
      X        : Integer;
      Y1       : Integer;
      Y2       : Integer;
      Color    : SDL.Video.Palettes.Colour
   ) is
      use SDL.Video.Renderers;
      use SDL.Video.Palettes;

      Clipped_Y1 : Integer := Y1;
      Clipped_Y2 : Integer := Y2;
   begin
      if Clipped_Y2 < Clipped_Y1 then
         declare
            Temp : Integer := Clipped_Y1;
         begin
            Clipped_Y1 := Clipped_Y2;
            Clipped_Y2 := Temp;
         end;
      end if;

      if Clipped_Y2 < 0 or else Clipped_Y1 >= Screen_Height or else X < 0 or else X >= Screen_Width then
         return;
      end if;

      if Clipped_Y1 < 0 then
         Clipped_Y1 := 0;
      end if;
      if Clipped_Y2 >= Screen_Height then
         Clipped_Y2 := Screen_Height - 1;
      end if;

      Set_Draw_Colour (Renderer, Color);
      Draw (Renderer, SDL.Coordinate (X), SDL.Coordinate (Clipped_Y1), SDL.Coordinate (X), SDL.Coordinate (Clipped_Y2));
   end Ver_Line;
begin
   SDL.Video.Windows.Makers.Create (
      Game_Win,
      "Ada Raycaster",
      SDL.Video.Windows.Centered_Window_Position,
      Win_Size
   );

   SDL.Video.Renderers.Makers.Create (Game_Ren, Game_Win);

   Last_Frame_Time := SDL.Timers.Ticks;

   while Running loop
      while SDL.Events.Events.Poll (Event) loop
         case Event.Common.Event_Type is
            when SDL.Events.Quit =>
               Running := False;

            when others =>
               null;
         end case;
      end loop;

      Game_Ren.Set_Draw_Colour (
         SDL.Video.Palettes.Colour'(0, 0, 0, 0)
      );
      Game_Ren.Clear;

      for X in 0 .. Screen_Width - 1 loop
         declare
            Camera_X : Float := 2.0 * Float (X) / Float (Screen_Width) - 1.0;
            Ray_Dir_X : Float := Dir_X + Plane_X * Camera_X;
            Ray_Dir_Y : Float := Dir_Y + Plane_Y * Camera_X;

            Map_X : Integer := Integer (Pos_X);
            Map_Y : Integer := Integer (Pos_Y);

            Side_Dist_X, Side_Dist_Y : Float;

            Delta_Dist_X : Float;
            Delta_Dist_Y : Float;
            Perp_Wall_Dist : Float := 0.0;

            Step_X, Step_Y : Integer;

            Hit : Integer := 0;
            Side : Integer;

            Color : SDL.Video.Palettes.Colour;
         begin
            if Ray_Dir_X = 0.0 then
               Delta_Dist_X := 1.0E+30;
            else
               Delta_Dist_X := abs (1.0 / Ray_Dir_X);
            end if;

            if Ray_Dir_Y = 0.0 then
               Delta_Dist_Y := 1.0E+30;
            else
               Delta_Dist_Y := abs (1.0 / Ray_Dir_Y);
            end if;

            if Ray_Dir_X < 0.0 then
               Step_X := -1;
               Side_Dist_X := (Pos_X - Float (Map_X)) * Delta_Dist_X;
            else
               Step_X := 1;
               Side_Dist_X := (Float (Map_X) + 1.0 - Pos_X) * Delta_Dist_X;
            end if;

            if Ray_Dir_Y < 0.0 then
               Step_Y := -1;
               Side_Dist_Y := (Pos_Y - Float (Map_Y)) * Delta_Dist_Y;
            else
               Step_Y := 1;
               Side_Dist_Y := (Float (Map_Y) + 1.0 - Pos_Y) * Delta_Dist_Y;
            end if;

            while Hit = 0 loop
               if Side_Dist_X < Side_Dist_Y then
                  Side_Dist_X := Side_Dist_X + Delta_Dist_X;
                  Map_X := Map_X + Step_X;
                  Side := 0;
               else
                  Side_Dist_Y := Side_Dist_Y + Delta_Dist_Y;
                  Map_Y := Map_Y + Step_Y;
                  Side := 1;
               end if;

               if World_Map(Map_X, Map_Y) > 0 then Hit := 1; end if;
            end loop;

            if Side = 0 then
               Perp_Wall_Dist := (Float(Map_X) - Pos_X + (1.0 - Float(Step_X)) / 2.0) / Ray_Dir_X;
            else
               Perp_Wall_Dist := (Float(Map_Y) - Pos_Y + (1.0 - Float(Step_Y)) / 2.0) / Ray_Dir_Y;
            end if;

            declare
               Line_Height : Integer := Integer (Float (Screen_Height) / Perp_Wall_Dist);
               Draw_Start  : Integer := -Line_Height / 2 + Screen_Height / 2;
               Draw_End    : Integer := Line_Height / 2 + Screen_Height / 2;
            begin
               if Draw_Start < 0 then Draw_Start := 0; end if;
               if Draw_End >= Screen_Height then Draw_End := Screen_Height - 1; end if;

               case World_Map (Map_X, Map_Y) is
                  when 1 => Color := (255, 0, 0, 255);
                  when 2 => Color := (0, 255, 0, 255);
                  when 3 => Color := (0, 0, 255, 255);
                  when 4 => Color := (255, 255, 255, 255);
                  when others => Color := (255, 222, 33, 255);
               end case;

               if Side = 1 then Color := Dim_Color (Color); end if;

               Ver_Line (Game_Ren, X, Draw_Start, Draw_End, Color);
            end;
         end;
      end loop;

      Time_To_Wait :=
        SDL.Timers.Milliseconds (Long_Integer (Frame_Target_Time))
        - (SDL.Timers.Ticks - Last_Frame_Time);

      if Time_To_Wait > 0 and then
         Time_To_Wait <= SDL.Timers.Milliseconds (Frame_Target_Time)
      then
         SDL.Timers.Wait_Delay (Time_To_Wait);
      end if;

      Delta_Time := Float (SDL.Timers.Ticks - Last_Frame_Time) / 1000.0;
      Last_Frame_Time := SDL.Timers.Ticks;

      Move_Speed := Delta_Time * 5.0;
      Rot_Speed := Delta_Time * 3.0;
      
      Keys := SDL.Inputs.Keyboards.Get_State;

      if Keys (SDL.Events.Keyboards.Scan_Code_Up) then
         if World_Map (Integer (Pos_X + Dir_X * Move_Speed), Integer (Pos_Y)) = 0 then
            Pos_X := Pos_X + Dir_X * Move_Speed;
         end if;
         if World_Map (Integer (Pos_X), Integer (Pos_Y + Dir_Y * Move_Speed)) = 0 then
            Pos_Y := Pos_Y + Dir_Y * Move_Speed;
         end if;
      end if;

      if Keys (SDL.Events.Keyboards.Scan_Code_Down) then
         if World_Map (Integer (Pos_X - Dir_X * Move_Speed), Integer (Pos_Y)) = 0 then
            Pos_X := Pos_X - Dir_X * Move_Speed;
         end if;
         if World_Map (Integer (Pos_X), Integer (Pos_Y - Dir_Y * Move_Speed)) = 0 then
            Pos_Y := Pos_Y - Dir_Y * Move_Speed;
         end if;
      end if;

      if Keys (SDL.Events.Keyboards.Scan_Code_Right) then
         declare
            Old_Dir_X   : Float := Dir_X;
            Old_Plane_X : Float := Plane_X;
         begin
            Dir_X := Dir_X * Cos (-Rot_Speed) - Dir_Y * Sin (-Rot_Speed);
            Dir_Y := Old_Dir_X * Sin (-Rot_Speed) + Dir_Y * Cos (-Rot_Speed);

            Plane_X := Plane_X * Cos (-Rot_Speed) - Plane_Y * Sin (-Rot_Speed);
            Plane_Y := Old_Plane_X * Sin (-Rot_Speed) + Plane_Y * Cos (-Rot_Speed);
         end;
      end if;

      if Keys (SDL.Events.Keyboards.Scan_Code_Left) then
         declare
            Old_Dir_X   : Float := Dir_X;
            Old_Plane_X : Float := Plane_X;
         begin
            Dir_X := Dir_X * Cos (Rot_Speed) - Dir_Y * Sin (Rot_Speed);
            Dir_Y := Old_Dir_X * Sin (Rot_Speed) + Dir_Y * Cos (Rot_Speed);

            Plane_X := Plane_X * Cos (Rot_Speed) - Plane_Y * Sin (Rot_Speed);
            Plane_Y := Old_Plane_X * Sin (Rot_Speed) + Plane_Y * Cos (Rot_Speed);
         end;
      end if;

      Game_Ren.Present;
   end loop;

   Game_Win.Finalize;
   Game_Ren.Finalize;
end Ada_Raycaster;
