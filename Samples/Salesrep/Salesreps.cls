/*------------------------------------------------------------------------
    File        : Salesreps
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Sun Nov 12 18:07:05 CET 2017
    Notes       : 
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING OpenEdge.Web.* FROM PROPATH.
USING Progress.Lang.* FROM PROPATH .
USING Progress.Json.ObjectModel.* FROM PROPATH.
USING Consultingwerk.Exceptions.* FROM PROPATH.
USING OpenEdge.Net.HTTP.* FROM PROPATH.
USING OpenEdge.Net.HTTP.Filter.Payload.* FROM PROPATH.
USING OpenEdge.Core.* FROM PROPATH.
USING OpenEdge.Net.HTTP.Filter.Writer.* FROM PROPATH.

CLASS Salesrep.Salesreps 
    INHERITS WebHandler: 

    DEFINE TEMP-TABLE ttSalesrep NO-UNDO SERIALIZE-NAME "Salesrep" LIKE Salesrep .

    METHOD PROTECTED JsonObject GetSalesrep (pcSalesrep AS CHARACTER):
        
        DEFINE VARIABLE oJson AS JsonObject NO-UNDO.

        EMPTY TEMP-TABLE ttSalesrep.
        
        FIND Salesrep WHERE Salesrep.Salesrep = pcSalesrep NO-LOCK NO-ERROR . 
        
        IF NOT AVAILABLE Salesrep THEN 
            UNDO, THROW NEW NotFoundException () .  

        oJson = NEW JsonObject () . 
        
        CREATE ttSalesrep .
        BUFFER-COPY Salesrep TO ttSalesrep .

        oJson:Read (BUFFER ttSalesrep:HANDLE) .

        RETURN oJson .

        FINALLY:
            EMPTY TEMP-TABLE ttSalesrep.                    
        END FINALLY.

    END METHOD.

    METHOD PROTECTED JsonArray GetSalesreps ():

        DEFINE VARIABLE oJson AS JsonArray NO-UNDO.

        EMPTY TEMP-TABLE ttSalesrep.
        
        FOR EACH Salesrep:
            CREATE ttSalesrep.
            BUFFER-COPY Salesrep TO ttSalesrep .
        END.
        
        oJson = NEW JsonArray () . 
        
        TEMP-TABLE ttSalesrep:WRITE-JSON ("JsonArray", oJson) .
        
        RETURN oJson .

        FINALLY:
            EMPTY TEMP-TABLE ttSalesrep.                    
        END FINALLY.
        
    END METHOD . 

    /**
     * Purpose: Handles the http GET
     * Notes:
     * @param poRequest The IWebRequest instance representing the call
     * @return StatusCode of the response sent to the client
     */
    METHOD OVERRIDE PROTECTED INTEGER HandleGet (poRequest AS OpenEdge.Web.IWebRequest):
        
        DEFINE VARIABLE cSalesrep   AS CHARACTER     NO-UNDO .
        DEFINE VARIABLE oJson       AS JsonConstruct NO-UNDO . 
        DEFINE VARIABLE oResponse   AS IHttpResponse NO-UNDO .
        
        ASSIGN oResponse             = NEW OpenEdge.Web.WebResponse ()
               oResponse:ContentType = 'application/json':U .

        ASSIGN cSalesrep = poRequest:GetPathParameter("Salesrep") .
        
        IF cSalesrep > "" THEN 
            oJson = THIS-OBJECT:GetSalesrep (cSalesrep) .
        ELSE 
            oJson = THIS-OBJECT:GetSalesreps () .


        oResponse:Entity = oJson .

        THIS-OBJECT:WriteResponse (oResponse).

        RETURN 200 .     

        CATCH err AS Progress.Lang.Error:
                
            IF TYPE-OF (err, NotFoundException) THEN DO: 
                oJson = NEW JsonObject () .
                CAST (oJson, JsonObject):Add ("error", err:GetMessage(1)) . 
                
                oResponse:Entity = oJson .
        
                THIS-OBJECT:WriteResponse (oResponse).
                
                RETURN 404 . /* not found */
            END.                
            ELSE DO: 
                oJson = NEW JsonObject () .
                CAST (oJson, JsonObject):Add ("error", err:GetMessage(1)) .
                
                oResponse:Entity = oJson .
        
                THIS-OBJECT:WriteResponse (oResponse).
                 
                RETURN 500 . /* internal server error */
            END.                
                
        END CATCH.

    END METHOD.

    /**
     * Purpose: Handler for unsupported methods. The request being serviced and
     *          an optional status code is returned. A zero or null value means
     *          this method will deal with all errors.
     * Notes:
     * @param poRequest The IWebRequest instance representing the call
     * @return StatusCode of the response sent to the client
     */
    METHOD OVERRIDE PROTECTED INTEGER HandleNotAllowedMethod (poRequest AS OpenEdge.Web.IWebRequest):

        /* Throwing an error from this method results in a 500/Internal Server Error response.
        The web handler will attempt to log this exception.

        See the HandleGet method's comments on choosing a value to return from this method. */

        UNDO, THROW NEW Progress.Lang.AppError ("METHOD NOT IMPLEMENTED":U).

    END METHOD.

    /**
     * Purpose: Handler for unknown methods. The request being serviced and an
     *          optional status code is returned. A zero or null value means
     *          this method will deal with all errors.
     * Notes:
     * @param poRequest The IWebRequest instance representing the call
     * @return StatusCode of the response sent to the client
     */
    METHOD OVERRIDE PROTECTED INTEGER HandleNotImplemented (poRequest AS OpenEdge.Web.IWebRequest):

        /* Throwing an error from this method results in a 500/Internal Server Error response.
        The web handler will attempt to log this exception.

        See the HandleGet method's comments on choosing a value to return from this method. */
        UNDO, THROW NEW Progress.Lang.AppError ("METHOD NOT IMPLEMENTED":U).

    END METHOD.

    /**
     * Purpose: Writes the HttpResponse to the stream
     * Notes:   Does handle OpenEdge.Core.String seperatly due to (PSC00348040)
     * @param poResponse The Response instance to write
     */
    METHOD PROTECTED VOID WriteResponse (poResponse AS IHttpResponse):

        DEFINE VARIABLE oWriter   AS WebResponseWriter NO-UNDO.
        DEFINE VARIABLE oCTWriter AS MessageWriter     NO-UNDO.
        DEFINE VARIABLE oBytes    AS ByteBucket        NO-UNDO.
        DEFINE VARIABLE mEntity   AS MEMPTR            NO-UNDO.

        DEFINE VARIABLE oBody     AS OpenEdge.Core.String NO-UNDO.

        /* dump to stream */
        oWriter = NEW WebResponseWriter (poResponse).
        oWriter:Open ().

        /* Convert from an image to bytes */
        IF VALID-OBJECT (poResponse:Entity) THEN DO:

            oCTWriter = BodyWriterBuilder:Build (poResponse):Writer.

            IF NOT TYPE-OF (poResponse:Entity, OpenEdge.Core.String) THEN DO ON ERROR UNDO, THROW:

                oCTWriter:Open ().
                oCTWriter:Write (poResponse:Entity).
                oCTWriter:Close ().

                oBytes = CAST (oCTWriter:Entity, ByteBucket).

                mEntity = oBytes:GetBytes ():VALUE.

                poResponse:ContentLength = GET-SIZE (mEntity).
                oWriter:Write (mEntity).

                FINALLY:
                    SET-SIZE (mEntity) = 0.
                END FINALLY.

            END.
            ELSE DO:

                oBody = CAST (poResponse:Entity, OpenEdge.Core.String).

                poResponse:ContentLength = oBody:Size.

                oWriter:Open ().

                /** HTTP MESSAGE ENTITY APPROACH **/
                /* The Progress.IO.OutputStream Write() methods take multiple overloads, for
                   a variety of data types. See the doc for more information. */
                oWriter:Write (oBody:Value).

            END.
        END.

        FINALLY:
            oWriter:Close ().
        END FINALLY.

    END METHOD.
END CLASS.
