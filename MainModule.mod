
MODULE WeldingModule
	CONST robtarget pHome:=[[855.16,-40.58,579.29],[0.00644155,0.981307,0.0177969,0.191516],[-1,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
	CONST robtarget pWeldForward:=[[2.66,8.33,226.35],[0.700632,-0.137167,0.130946,0.687861],[0,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
	CONST robtarget pWeldBackward:=[[9.04,57.56,226.36],[0.703038,0.131894,0.134114,-0.685824],[0,-1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
	CONST robtarget pClean:=[[780.14,-272.49,444.50],[0.105566,-0.782962,-0.591371,-0.161577],[-1,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
	TASK PERS tooldata tWeldTip:=[TRUE,[[33.1132,-7.22908,232.709],[0.981449,-0.0109399,0.191337,0.00526543]],[1,[0,0,10],[1,0,0,0],0,0,0]];
	TASK PERS wobjdata WeldPart:=[FALSE,TRUE,"",[[914.28,197.095,483.668],[5.10288E-06,-0.0155527,-0.999879,-5.41927E-07]],[[0,0,0],[1,0,0,0]]];
	VAR num n_weldForward:=0;
	VAR num n_weldBackward:=0;
	VAR num n_weldUp:=0;
	VAR num TipCleanDue:=0;
	VAR num ForwardOffset:=0;
	VAR num BackwardOffset:=0;
	VAR num UpOffset:=0;
	PROC GripOpen()
		Reset CLOSE_AandB_GRIPPERS;
		Set OPEN_AandB_GRIPPERS;
		WaitDI GRIPPER_A_CLOSED, 0;
		WaitDI GRIPPER_B_CLOSED, 0;
		WaitDI GRIPPER_A_OPENED, 1;
		WaitDI GRIPPER_B_OPENED, 1;
	ENDPROC
	PROC GripClose()
		Reset OPEN_AandB_GRIPPERS;
		Set CLOSE_AandB_GRIPPERS;
		WaitDI GRIPPER_A_CLOSED, 1;
		WaitDI GRIPPER_B_CLOSED, 1;
		WaitDI GRIPPER_A_OPENED, 0;
		WaitDI GRIPPER_B_OPENED, 0;
	ENDPROC
	PROC TipClean()
		! moves to home position
		MoveJ pHome, v1000, z50, tWeldTip;
		! moves to the clean position pounce, z offset needs to be adjusted
		MoveJ RelTool(pClean,0,0,-100), v1000, z10, tWeldTip;
		! moves to the clean position, may need a wait after
		MoveL pClean, v200, fine, tWeldTip;
		WaitTime 2;
		! moves back to the clean position pounce
		MoveL RelTool(pClean,0,0,-100), v200, fine, tWeldTip;
		! moves back home
		MoveJ pHome, v1000, z50, tWeldTip;
	ENDPROC
	PROC WeldLoop()
		! moves to home position
		MoveJ pHome, v1000, z50, tWeldTip;
		FOR i FROM 1 TO 5 DO
			! clears the weld pass counts
			n_weldForward := 0;
			n_weldBackward := 0;
			! moves to a intermediate pounce position above the weld
			MoveJ Offs(pWeldForward,ForwardOffset,0,UpOffset - 100), v1000, z50, tWeldTip\WObj:=WeldPart;
			FOR j FROM 1 TO 3 DO
				! moves to the pre-weld forward position
				MoveJ Offs(pWeldForward,ForwardOffset,0,UpOffset - 25), v1000, z10, tWeldTip\WObj:=WeldPart;
				! moves to the weld forward position
				MoveL Offs(pWeldForward, ForwardOffset, 0, UpOffset), v1000, fine, tWeldTip\WObj:=WeldPart;
				! Weld
				MoveL Offs(pWeldForward, ForwardOffset, 50, UpOffset), v40, fine, tWeldTip\WObj:=WeldPart;
				! Weldstop, incriments the forward pass count and sets the offset
				Incr n_weldForward;
				ForwardOffset := n_weldForward * 10;
				! moves to the pounce position above the forward pass
				MoveL Offs(pWeldForward, ForwardOffset, 50, UpOffset - 25), v1000, z10, tWeldTip\WObj:=WeldPart;
				! moves to the back pass pounce
				MoveJ Offs(pWeldBackward,BackwardOffset,0,UpOffset - 25), v1000, z10, tWeldTip\WObj:=WeldPart;
				! repositions to back pass position
				MoveL Offs(pWeldBackward, BackwardOffset, 0, UpOffset), v1000, fine, tWeldTip\WObj:=WeldPart;
				! Weld
				MoveL Offs(pWeldBackward, BackwardOffset, -50, UpOffset), v40, fine, tWeldTip\WObj:=WeldPart;
				! Weldstop, incriments the backward pass count and sets the offset
				Incr n_weldBackward;
				BackwardOffset := n_weldBackward * 10;
				! Moves to the pounce position above the last weld
				MoveL Offs(pWeldBackward, BackwardOffset, -50, UpOffset - 25), v1000, z10, tWeldTip\WObj:=WeldPart;
			ENDFOR
		! incriments the up pass count and sets the offset
		Incr n_weldUp;
		UpOffset := n_weldUp * -2;
		ENDFOR
		! resets the pass counts
		n_weldUp := 0;
		! incriments the tip clean count
		Incr TipCleanDue;
		! moves back home
		MoveJ pHome, v1000, z50, tWeldTip;
	ENDPROC
	PROC MainWeld()
		! calls the WeldLoop procedure if the groupinput is on
		IF gI_ProgSelect = 7 THEN
			WHILE TipCleanDue >= 2 DO
				TipClean;
				TipCleanDue := 0;
			ENDWHILE
			WeldLoop;
		ENDIF
	ENDPROC
ENDMODULE