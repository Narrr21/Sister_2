       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKING.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "input.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN.
           SELECT ACC-FILE ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACC.
           SELECT TMP-FILE ASSIGN TO "temp.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TMP.
           SELECT OUT-FILE ASSIGN TO "output.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT.

       DATA DIVISION.
       FILE SECTION.

       FD IN-FILE.
       01 IN-RECORD             PIC X(19).

       FD ACC-FILE.
       01 ACC-RECORD-RAW        PIC X(19).

       FD TMP-FILE.
       01 TMP-RECORD            PIC X(19).

       FD OUT-FILE.
       01 OUT-RECORD            PIC X(120).

       WORKING-STORAGE SECTION.
       77 WS-IN                 PIC XX.
       77 WS-ACC                PIC XX.
       77 WS-TMP                PIC XX.
       77 WS-OUT                PIC XX.
       
       77 IN-ACCOUNT            PIC 9(6).
       77 IN-ACTION             PIC X(3).
       77 IN-AMOUNT             PIC 9(9)V99.

       77 ACC-ACCOUNT           PIC 9(6).
       77 ACC-ACTION            PIC X(3).
       77 ACC-BALANCE           PIC 9(9)V99.

       77 NEW-BALANCE           PIC 9(9)V99 VALUE 0.
       77 MATCH-FOUND           PIC X VALUE "N".
       77 UPDATED               PIC X VALUE "N".
       77 WS-EOF                PIC X VALUE "N".

       77 DISP-AMOUNT           PIC 9(9).99.
       77 IDR-BALANCE           PIC 9(12)V99 VALUE 0.
       77 IDR-BALANCE-DISP      PIC Z,ZZZ,ZZZ,ZZ9.99.

       77 RAIUSD-RT             PIC 9(6) VALUE 7358.
       77 USDIDR-RT             PIC 9(6) VALUE 16270.

       PROCEDURE DIVISION.

       MAIN.
           PERFORM READ-INPUT
           PERFORM PROCESS-RECORDS
           
           IF MATCH-FOUND = "N"
               IF IN-ACTION = "NEW"
                   PERFORM APPEND-ACCOUNT
                   MOVE "ACCOUNT CREATED" TO OUT-RECORD
                   PERFORM WRITE-OUTPUT
               ELSE
                   MOVE "ACCOUNT NOT FOUND" TO OUT-RECORD
                   PERFORM WRITE-OUTPUT
               END-IF
           ELSE
               IF IN-ACTION = "NEW"
                   MOVE "ACCOUNT ALREADY EXISTS" TO OUT-RECORD
                   PERFORM WRITE-OUTPUT
               END-IF
           END-IF
           
           PERFORM FINALIZE
           STOP RUN.

       READ-INPUT.
           OPEN INPUT IN-FILE
           IF WS-IN NOT = "00"
               DISPLAY "IN-FILE OPEN FAILED, STATUS = " WS-IN
               STOP RUN
           END-IF
           
           READ IN-FILE
           IF WS-IN = "10"
               DISPLAY "NO INPUT"
               CLOSE IN-FILE
               STOP RUN
           ELSE
               IF WS-IN NOT = "00"
                   DISPLAY "IN-FILE READ FAILED, STATUS = " WS-IN
                   CLOSE IN-FILE
                   STOP RUN
               END-IF
           END-IF
           
           CLOSE IN-FILE
           IF WS-IN NOT = "00"
               DISPLAY "IN-FILE CLOSE FAILED, STATUS = " WS-IN
           END-IF

           MOVE IN-RECORD(1:6) TO IN-ACCOUNT
           MOVE IN-RECORD(7:3) TO IN-ACTION
           MOVE FUNCTION NUMVAL(IN-RECORD(10:9)) TO IN-AMOUNT.

       PROCESS-RECORDS.
           OPEN INPUT ACC-FILE
           IF WS-ACC NOT = "00" AND WS-ACC NOT = "35"
               DISPLAY "ACC-FILE OPEN FAILED, STATUS = " WS-ACC
               STOP RUN
           END-IF
           
           IF WS-ACC = "35"
               CLOSE ACC-FILE
               OPEN OUTPUT TMP-FILE
               IF WS-TMP NOT = "00"
                   DISPLAY "TMP-FILE CREATE FAILED, STATUS = " WS-TMP
                   STOP RUN
               END-IF
               CLOSE TMP-FILE
               EXIT PARAGRAPH
           END-IF
           
           OPEN OUTPUT TMP-FILE
           IF WS-TMP NOT = "00"
               DISPLAY "TMP-FILE OPEN FAILED, STATUS = " WS-TMP
               CLOSE ACC-FILE
               STOP RUN
           END-IF
           
           MOVE "N" TO WS-EOF
           PERFORM UNTIL WS-EOF = "Y"
               READ ACC-FILE
               EVALUATE WS-ACC
                   WHEN "00"
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       MOVE ACC-RECORD-RAW(7:3) TO ACC-ACTION
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:9))
                           TO ACC-BALANCE
                       IF ACC-ACCOUNT = IN-ACCOUNT
                           MOVE "Y" TO MATCH-FOUND
                           IF IN-ACTION NOT = "NEW"
                               PERFORM APPLY-ACTION
                           ELSE
                               WRITE TMP-RECORD FROM ACC-RECORD-RAW
                               IF WS-TMP NOT = "00"
                                   DISPLAY "TMP WRITE FAILED, STATUS = " 
                                           WS-TMP
                                   MOVE "Y" TO WS-EOF
                               END-IF
                           END-IF
                       ELSE
                           WRITE TMP-RECORD FROM ACC-RECORD-RAW
                           IF WS-TMP NOT = "00"
                               DISPLAY "TMP WRITE FAILED, STATUS = " 
                                       WS-TMP
                               MOVE "Y" TO WS-EOF
                           END-IF
                       END-IF
                   WHEN "10"
                       MOVE "Y" TO WS-EOF
                   WHEN OTHER
                       DISPLAY "ACC-FILE READ FAILED, STATUS = " WS-ACC
                       MOVE "Y" TO WS-EOF
               END-EVALUATE
           END-PERFORM
           
           CLOSE TMP-FILE
           IF WS-TMP NOT = "00"
               DISPLAY "TMP-FILE CLOSE FAILED, STATUS = " WS-TMP
           END-IF
           
           CLOSE ACC-FILE
           IF WS-ACC NOT = "00"
               DISPLAY "ACC-FILE CLOSE FAILED, STATUS = " WS-ACC
           END-IF.

       APPLY-ACTION.
           MOVE ACC-BALANCE TO NEW-BALANCE
           EVALUATE IN-ACTION
               WHEN "DEP"
                   ADD IN-AMOUNT TO NEW-BALANCE
                   MOVE "DEPOSITED MONEY" TO OUT-RECORD
                   PERFORM WRITE-OUTPUT
               WHEN "WDR"
                   IF NEW-BALANCE >= IN-AMOUNT
                       SUBTRACT IN-AMOUNT FROM NEW-BALANCE
                       MOVE "WITHDREW MONEY" TO OUT-RECORD
                   ELSE
                       MOVE "INSUFFICIENT FUNDS" TO OUT-RECORD
                   END-IF
                   PERFORM WRITE-OUTPUT
               WHEN "BAL"
                   PERFORM CALCULATE-IDR-BALANCE
                   MOVE SPACES TO OUT-RECORD
                   STRING "BALANCE: " DELIMITED BY SIZE
                          NEW-BALANCE DELIMITED BY SIZE
                          " Rai Stones (IDR " DELIMITED BY SIZE
                          IDR-BALANCE-DISP DELIMITED BY SIZE
                          ")" DELIMITED BY SIZE
                          INTO OUT-RECORD
                   PERFORM WRITE-OUTPUT
               WHEN OTHER
                   MOVE "UNKNOWN ACTION" TO OUT-RECORD
                   PERFORM WRITE-OUTPUT
           END-EVALUATE

           MOVE IN-ACCOUNT  TO TMP-RECORD(1:6)
           MOVE IN-ACTION   TO TMP-RECORD(7:3)
           MOVE NEW-BALANCE TO DISP-AMOUNT
           MOVE DISP-AMOUNT TO TMP-RECORD(10:9)

           WRITE TMP-RECORD
           IF WS-TMP NOT = "00"
               DISPLAY "TMP WRITE BALANCE FAILED, STATUS = " WS-TMP
           ELSE
               MOVE "Y" TO UPDATED
           END-IF.

       CALCULATE-IDR-BALANCE.
           COMPUTE IDR-BALANCE = NEW-BALANCE * RAIUSD-RT * USDIDR-RT
           MOVE IDR-BALANCE TO IDR-BALANCE-DISP.

       APPEND-ACCOUNT.
           OPEN EXTEND ACC-FILE
           IF WS-ACC NOT = "00"
               IF WS-ACC = "35"
                   OPEN OUTPUT ACC-FILE
                   IF WS-ACC NOT = "00"
                       DISPLAY "ACC-FILE CREATE FAILED, STATUS = " 
                               WS-ACC
                       EXIT PARAGRAPH
                   END-IF
                   CLOSE ACC-FILE
                   OPEN EXTEND ACC-FILE
                   IF WS-ACC NOT = "00"
                       DISPLAY "ACC-FILE EXTEND FAILED, STATUS = " 
                               WS-ACC
                       EXIT PARAGRAPH
                   END-IF
               ELSE
                   DISPLAY "ACC-FILE EXTEND FAILED, STATUS = " WS-ACC
                   EXIT PARAGRAPH
               END-IF
           END-IF
           
           MOVE IN-ACCOUNT TO ACC-RECORD-RAW(1:6)
           MOVE IN-ACTION  TO ACC-RECORD-RAW(7:3)
           MOVE IN-AMOUNT  TO DISP-AMOUNT
           MOVE DISP-AMOUNT TO ACC-RECORD-RAW(10:9)
           
           WRITE ACC-RECORD-RAW
           IF WS-ACC NOT = "00"
               DISPLAY "ACC-FILE WRITE FAILED, STATUS = " WS-ACC
           END-IF
           
           CLOSE ACC-FILE
           IF WS-ACC NOT = "00"
               DISPLAY "ACC-FILE CLOSE AFTER APPEND FAILED, STATUS = " 
                       WS-ACC
           END-IF.

       WRITE-OUTPUT.
           OPEN OUTPUT OUT-FILE
           IF WS-OUT NOT = "00"
               DISPLAY "OUT-FILE OPEN FAILED, STATUS = " WS-OUT
               EXIT PARAGRAPH
           END-IF
           
           WRITE OUT-RECORD
           IF WS-OUT NOT = "00"
               DISPLAY "OUT-FILE WRITE FAILED, STATUS = " WS-OUT
           END-IF
           
           CLOSE OUT-FILE
           IF WS-OUT NOT = "00"
               DISPLAY "OUT-FILE CLOSE FAILED, STATUS = " WS-OUT
           END-IF.

       FINALIZE.
           IF UPDATED = "Y"
               CALL "SYSTEM" USING BY CONTENT "mv temp.txt accounts.txt"
           END-IF.
