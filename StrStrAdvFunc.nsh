!include LogicLib.nsh


  # Function StrStrAdv
  ##################

  !macro FUNCTION_STRING_StrStrAdv
    !insertmacro STRFUNC_FUNC `StrStrAdv` `2003-2004 Diego Pedroso`

    /*After this point:
      ------------------------------------------
       $0 = String (input)
       $1 = StringToSearch (input)
       $2 = DirectionOfSearch (input)
       $3 = DirectionOfReturn (input)
       $4 = ShowStrToSearch (input)
       $5 = NumLoops (input)
       $6 = CaseSensitive (input)
       $7 = StringLength (temp)
       $8 = StrToSearchLength (temp)
       $9 = CurrentLoop (temp)
       $R0 = EndCharPos (temp)
       $R1 = StartCharPos (temp)
       $R2 = OutVar (output)
       $R3 = Temp (temp)*/

      ;Get input from user

      Exch $6
      Exch
      Exch $5
      Exch
      Exch 2
      Exch $4
      Exch 2
      Exch 3
      Exch $3
      Exch 3
      Exch 4
      Exch $2
      Exch 4
      Exch 5
      Exch $1
      Exch 5
      Exch 6
      Exch $0
      Exch 6
      Push $7
      Push $8
      Push $9
      Push $R3
      Push $R2
      Push $R1
      Push $R0

      ; Clean $R0-$R3 variables
      StrCpy $R0 ""
      StrCpy $R1 ""
      StrCpy $R2 ""
      StrCpy $R3 ""

      ; Verify if we have the correct values on the variables
      ${If} $0 == ``
        SetErrors ;AdvStrStr_StrToSearch not found
        Goto AdvStrStr_End
      ${EndIf}

      ${If} $1 == ``
        SetErrors ;No text to search
        Goto AdvStrStr_End
      ${EndIf}

      ${If} $2 != <
        StrCpy $2 >
      ${EndIf}

      ${If} $3 != <
        StrCpy $3 >
      ${EndIf}

      ${If} $4 <> 0
        StrCpy $4 1
      ${EndIf}

      ${If} $5 <= 0
        StrCpy $5 0
      ${EndIf}

      ${If} $6 <> 1
        StrCpy $6 0
      ${EndIf}

      ; Find "AdvStrStr_String" length
      StrLen $7 $0

      ; Then find "AdvStrStr_StrToSearch" length
      StrLen $8 $1

      ; Now set up basic variables

      ${If} $2 == <
        IntOp $R1 $7 - $8
        StrCpy $R2 $7
      ${Else}
        StrCpy $R1 0
        StrCpy $R2 $8
      ${EndIf}

      StrCpy $9 0 ; First loop

      ;Let's begin the search

      ${Do}
        ; Step 1: If the starting or ending numbers are negative
        ;         or more than AdvStrStr_StringLen, we return
        ;         error

        ${If} $R1 < 0
          StrCpy $R1 ``
          StrCpy $R2 ``
          StrCpy $R3 ``
          SetErrors ;AdvStrStr_StrToSearch not found
          Goto AdvStrStr_End
        ${ElseIf} $R2 > $7
          StrCpy $R1 ``
          StrCpy $R2 ``
          StrCpy $R3 ``
          SetErrors ;AdvStrStr_StrToSearch not found
          Goto AdvStrStr_End
        ${EndIf}

        ; Step 2: Start the search depending on
        ;         AdvStrStr_DirectionOfSearch. Chop down not needed
        ;         characters.

        ${If} $R1 <> 0
          StrCpy $R3 $0 `` $R1
        ${EndIf}

        ${If} $R2 <> $7
          ${If} $R1 = 0
            StrCpy $R3 $0 $8
          ${Else}
            StrCpy $R3 $R3 $8
          ${EndIf}
        ${EndIf}

        ; Step 3: Make sure that's the string we want

        ; Case-Sensitive Support <- Use "AdvStrStr_Temp"
        ; variable because it won't be used anymore

        ${If} $6 == 1
          System::Call `kernel32::lstrcmp(ts, ts) i.s` `$R3` `$1`
          Pop $R3
          ${If} $R3 = 0
            StrCpy $R3 1 ; Continue
          ${Else}
            StrCpy $R3 0 ; Break
          ${EndIf}
        ${Else}
          ${If} $R3 == $1
            StrCpy $R3 1 ; Continue
          ${Else}
            StrCpy $R3 0 ; Break
          ${EndIf}
        ${EndIf}

        ; After the comparasion, confirm that it is the
        ; value we want.

        ${If} $R3 = 1

          ;We found it, return except if the user has set up to
          ;search for another one:
          ${If} $9 >= $5

            ;Now, let's see if the user wants
            ;AdvStrStr_StrToSearch to appear:
            ${If} $4 == 0
              ;Return depends on AdvStrStr_DirectionOfReturn
              ${If} $3 == <
                ; RTL
                StrCpy $R0 $0 $R1
              ${Else}
                ; LTR
                StrCpy $R0 $0 `` $R2
              ${EndIf}
              ${Break}
            ${Else}
              ;Return depends on AdvStrStr_DirectionOfReturn
              ${If} $3 == <
                ; RTL
                StrCpy $R0 $0 $R2
              ${Else}
                ; LTR
                StrCpy $R0 $0 `` $R1
              ${EndIf}
              ${Break}
            ${EndIf}
          ${Else}
            ;If the user wants to have more loops, let's do it so!
            IntOp $9 $9 + 1

            ${If} $2 == <
              IntOp $R1 $R1 - 1
              IntOp $R2 $R2 - 1
            ${Else}
              IntOp $R1 $R1 + 1
              IntOp $R2 $R2 + 1
            ${EndIf}
          ${EndIf}
        ${Else}
          ; Step 4: We didn't find it, so do steps 1 thru 3 again

          ${If} $2 == <
            IntOp $R1 $R1 - 1
            IntOp $R2 $R2 - 1
          ${Else}
            IntOp $R1 $R1 + 1
            IntOp $R2 $R2 + 1
          ${EndIf}
        ${EndIf}
      ${Loop}

      AdvStrStr_End:

      ;Add 1 to AdvStrStr_EndCharPos to be supportable
      ;by "StrCpy"

      IntOp $R2 $R2 - 1

      ;Return output to user

      Exch $R0
      Exch
      Pop $R1
      Exch
      Pop $R2
      Exch
      Pop $R3
      Exch
      Pop $9
      Exch
      Pop $8
      Exch
      Pop $7
      Exch
      Pop $6
      Exch
      Pop $5
      Exch
      Pop $4
      Exch
      Pop $3
      Exch
      Pop $2
      Exch
      Pop $1
      Exch
      Pop $0

    FunctionEnd

  !macroend

  !macro FUNCTION_STRING_StrStrAdv_Call ResultVar String StrToSearchFor SearchDirection ResultStrDirection DisplayStrToSearch Loops CaseSensitive
    !verbose push
    !verbose 4
    !echo `$ {StrStrAdv} "${ResultVar}" "${String}" "${StrToSearchFor}" "${SearchDirection}" "${ResultStrDirection}" "${DisplayStrToSearch}" "${Loops}" "${CaseSensitive}"`
    !verbose pop

    Push `${String}`
    Push `${StrToSearchFor}`
    Push `${SearchDirection}`
    Push `${ResultStrDirection}`
    Push `${DisplayStrToSearch}`
    Push `${Loops}`
    Push `${CaseSensitive}`
    Call StrStrAdv
    Pop `${ResultVar}`
  !macroend


  !macro FUNCTION_STRING_UnStrStrAdv_Call ResultVar String StrToSearchFor SearchDirection ResultStrDirection DisplayStrToSearch Loops CaseSensitive
    !verbose push
    !verbose 4
    !echo `$ {UnStrStrAdv} "${ResultVar}" "${String}" "${StrToSearchFor}" "${SearchDirection}" "${ResultStrDirection}" "${DisplayStrToSearch}" "${Loops}" "${CaseSensitive}"`
    !verbose pop

    Push `${String}`
    Push `${StrToSearchFor}`
    Push `${SearchDirection}`
    Push `${ResultStrDirection}`
    Push `${DisplayStrToSearch}`
    Push `${Loops}`
    Push `${CaseSensitive}`
    Call un.StrStrAdv
    Pop `${ResultVar}`
  !macroend

