/*------------------------------------------------------------------------
    File        : NotFoundException
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mikef
    Created     : Sun Nov 12 18:20:50 CET 2017
    Notes       : 
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.*.

CLASS Consultingwerk.Exceptions.NotFoundException 
    INHERITS AppError: 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PUBLIC NotFoundException ():
        SUPER ("The requested resource was not found", 404).
        
    END CONSTRUCTOR.

END CLASS.
