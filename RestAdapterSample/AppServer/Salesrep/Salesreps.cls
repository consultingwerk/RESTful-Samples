@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
/*------------------------------------------------------------------------
    File        : Salesreps
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mikef
    Created     : Mon Nov 13 20:39:35 CET 2017
    Notes       : 
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.* FROM PROPATH.
USING Progress.Lang.*.

CLASS Salesrep.Salesreps: 

    DEFINE TEMP-TABLE ttSalesrep NO-UNDO SERIALIZE-NAME "Salesrep" LIKE Salesrep .

    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC LONGCHAR GetSalesrep (pcSalesrep AS CHARACTER):
        
        DEFINE VARIABLE oJson      AS JsonObject NO-UNDO .
        DEFINE VARIABLE lcLongchar AS LONGCHAR   NO-UNDO . 

        EMPTY TEMP-TABLE ttSalesrep.
        
        FIND Salesrep WHERE Salesrep.Salesrep = pcSalesrep NO-LOCK NO-ERROR . 
        
        oJson = NEW JsonObject () . 
        
        CREATE ttSalesrep .
        BUFFER-COPY Salesrep TO ttSalesrep .

        oJson:Read (BUFFER ttSalesrep:HANDLE) .

        oJson:Write (INPUT-OUTPUT lcLongchar) .

        RETURN lcLongchar .

        FINALLY:
            EMPTY TEMP-TABLE ttSalesrep.                    
        END FINALLY.

    END METHOD.

    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC LONGCHAR GetSalesreps ():

        DEFINE VARIABLE oJson      AS JsonArray NO-UNDO.
        DEFINE VARIABLE lcLongchar AS LONGCHAR  NO-UNDO . 

        EMPTY TEMP-TABLE ttSalesrep.
        
        FOR EACH Salesrep:
            CREATE ttSalesrep.
            BUFFER-COPY Salesrep TO ttSalesrep .
        END.
        
        oJson = NEW JsonArray () . 
        
        TEMP-TABLE ttSalesrep:WRITE-JSON ("JsonArray", oJson) .
        
        oJson:Write (INPUT-OUTPUT lcLongchar) .

        RETURN lcLongchar .

        FINALLY:
            EMPTY TEMP-TABLE ttSalesrep.                    
        END FINALLY.
        
    END METHOD . 

END CLASS.