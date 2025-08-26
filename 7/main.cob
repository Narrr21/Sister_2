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
       01 IN-RECORD             PIC X(18).
       FD ACC-FILE.
       01 ACC-RECORD-RAW        PIC X(18).
       FD TMP-FILE.
       01 TMP-RECORD            PIC X(18).
       FD OUT-FILE.
       01 OUT-RECORD-FD         PIC X(120).

       WORKING-STORAGE SECTION.
       77 WS-IN                 PIC XX.
       77 WS-ACC                PIC XX.
       77 WS-TMP                PIC XX.
       77 WS-OUT                PIC XX.
       77 OUT-RECORD            PIC X(120).
       77 WS-WRITE-BUFFER       PIC X(120).
       77 IN-ACCOUNT            PIC 9(6).
       77 IN-ACTION             PIC X(3).
       77 IN-AMOUNT             PIC 9(6)V99.
       77 ACC-ACCOUNT           PIC 9(6).
       77 ACC-BALANCE           PIC 9(6)V99.
       77 NEW-BALANCE           PIC 9(6)V99 VALUE 0.
       77 MATCH-FOUND           PIC X VALUE "N".
       77 UPDATED               PIC X VALUE "N".
       77 WS-EOF                PIC X VALUE "N".
       77 WS-AMOUNT-STR         PIC 9(6).99.
       77 IDR-BALANCE           PIC 9(12)V99 VALUE 0.
       77 IDR-BALANCE-DISP      PIC Z,ZZZ,ZZZ,ZZ9.99.
       77 RAIUSD-RT             PIC 9(6) VALUE 7358.
       77 USDIDR-RT             PIC 9(6) VALUE 16270.
       77 WS-ARG-COUNT          PIC 9(2).
       77 WS-ARG-VALUE          PIC X(20).
       77 INTEREST-RATE         PIC V9(12) VALUE 0.000000036466.
       77 INTEREST-GAINED       PIC 9(6)V99.

       PROCEDURE DIVISION.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT > 0
               ACCEPT WS-ARG-VALUE FROM ARGUMENT-VALUE
               IF FUNCTION TRIM(WS-ARG-VALUE) = "--apply-interest"
                   PERFORM APPLY-INTEREST-FOREVER
               END-IF
           END-IF.

       MAIN-TRANSACTION.
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

       APPLY-INTEREST-FOREVER.
           PERFORM FOREVER
               CALL "SYSTEM" USING "sleep 23"
               PERFORM CALCULATE-ALL-INTEREST
           END-PERFORM.

       CALCULATE-ALL-INTEREST.
           OPEN I-O ACC-FILE
           IF WS-ACC NOT = "00" AND WS-ACC NOT = "35" EXIT PARAGRAPH.
           IF WS-ACC = "35" CLOSE ACC-FILE, EXIT PARAGRAPH.
           MOVE "N" TO WS-EOF
           PERFORM UNTIL WS-EOF = "Y"
               READ ACC-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       PERFORM APPLY-INTEREST-TO-RECORD
               END-READ
           END-PERFORM
           CLOSE ACC-FILE.

       APPLY-INTEREST-TO-RECORD.
           MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
           MOVE FUNCTION NUMVAL-C(ACC-RECORD-RAW(10:9)) TO ACC-BALANCE
           COMPUTE INTEREST-GAINED = ACC-BALANCE * INTEREST-RATE
           COMPUTE NEW-BALANCE = ACC-BALANCE + INTEREST-GAINED
           MOVE NEW-BALANCE TO WS-AMOUNT-STR
           STRING ACC-ACCOUNT   DELIMITED BY SIZE
                  "BAL"         DELIMITED BY SIZE
                  WS-AMOUNT-STR DELIMITED BY SIZE
                  INTO ACC-RECORD-RAW
           END-STRING
           REWRITE ACC-RECORD-RAW.

       READ-INPUT.
           OPEN INPUT IN-FILE
           IF WS-IN NOT = "00" STOP RUN.
           READ IN-FILE
           IF WS-IN NOT = "00" STOP RUN.
           CLOSE IN-FILE
           MOVE IN-RECORD(1:6) TO IN-ACCOUNT
           MOVE IN-RECORD(7:3) TO IN-ACTION
           MOVE FUNCTION NUMVAL-C(IN-RECORD(10:9)) TO IN-AMOUNT.

       PROCESS-RECORDS.
           OPEN INPUT ACC-FILE
           IF WS-ACC = "35" CLOSE ACC-FILE, EXIT PARAGRAPH.
           IF WS-ACC NOT = "00" STOP RUN.
           OPEN OUTPUT TMP-FILE
           IF WS-TMP NOT = "00" STOP RUN.
           MOVE "N" TO WS-EOF
           PERFORM UNTIL WS-EOF = "Y"
               READ ACC-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       IF ACC-ACCOUNT = IN-ACCOUNT
                           MOVE "Y" TO MATCH-FOUND
                           IF IN-ACTION NOT = "NEW"
                               PERFORM APPLY-ACTION
                           ELSE
                               WRITE TMP-RECORD FROM ACC-RECORD-RAW
                           END-IF
                       ELSE
                           WRITE TMP-RECORD FROM ACC-RECORD-RAW
                       END-IF
               END-READ
           END-PERFORM
           CLOSE ACC-FILE
           CLOSE TMP-FILE.

       APPLY-ACTION.
           MOVE FUNCTION NUMVAL-C(ACC-RECORD-RAW(10:9)) TO ACC-BALANCE
           MOVE ACC-BALANCE TO NEW-BALANCE
           EVALUATE IN-ACTION
               WHEN "DEP"
                   ADD IN-AMOUNT TO NEW-BALANCE
                   MOVE "DEPOSITED MONEY" TO OUT-RECORD
               WHEN "WDR"
                   IF NEW-BALANCE >= IN-AMOUNT
                       SUBTRACT IN-AMOUNT FROM NEW-BALANCE
                       MOVE "WITHDREW MONEY" TO OUT-RECORD
                   ELSE
                       MOVE "INSUFFICIENT FUNDS" TO OUT-RECORD
                   END-IF
               WHEN "BAL"
                   PERFORM CALCULATE-IDR-BALANCE
                   MOVE NEW-BALANCE TO WS-AMOUNT-STR
                   STRING "BALANCE: "      DELIMITED BY SIZE
                          WS-AMOUNT-STR    DELIMITED BY SIZE
                          " Rai Stones (IDR " DELIMITED BY SIZE
                          IDR-BALANCE-DISP DELIMITED BY SIZE
                          ")"              DELIMITED BY SIZE
                          INTO OUT-RECORD
                   END-STRING
           END-EVALUATE
           
           PERFORM WRITE-OUTPUT
           
           MOVE "Y" TO UPDATED
           MOVE NEW-BALANCE TO WS-AMOUNT-STR
           STRING IN-ACCOUNT   DELIMITED BY SIZE
                  IN-ACTION   DELIMITED BY SIZE
                  WS-AMOUNT-STR DELIMITED BY SIZE
                  INTO TMP-RECORD
           END-STRING
           WRITE TMP-RECORD.

       CALCULATE-IDR-BALANCE.
           COMPUTE IDR-BALANCE = NEW-BALANCE * RAIUSD-RT * USDIDR-RT.
           MOVE IDR-BALANCE TO IDR-BALANCE-DISP.

       APPEND-ACCOUNT.
           OPEN EXTEND ACC-FILE
           IF WS-ACC = "35"
              CLOSE ACC-FILE
              OPEN OUTPUT ACC-FILE
              CLOSE ACC-FILE
              OPEN EXTEND ACC-FILE
           END-IF
           MOVE 0 TO NEW-BALANCE
           MOVE NEW-BALANCE TO WS-AMOUNT-STR
           STRING IN-ACCOUNT   DELIMITED BY SIZE
                  "NEW"       DELIMITED BY SIZE
                  WS-AMOUNT-STR DELIMITED BY SIZE
                  INTO ACC-RECORD-RAW
           END-STRING
           WRITE ACC-RECORD-RAW
           CLOSE ACC-FILE.

       WRITE-OUTPUT.
           OPEN OUTPUT OUT-FILE.
           MOVE OUT-RECORD TO WS-WRITE-BUFFER.
           WRITE OUT-RECORD-FD FROM WS-WRITE-BUFFER.
           CLOSE OUT-FILE.

       FINALIZE.
           IF UPDATED = "Y"
               CALL "SYSTEM" USING "mv temp.txt accounts.txt"
           END-IF.
