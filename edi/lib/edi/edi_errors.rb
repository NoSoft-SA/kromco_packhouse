# Error class for validating schemas and for validating data against schemas.
class EdiValidationError < RuntimeError; end

# Error class for EDI Input processing.
class EdiInError < RuntimeError; end

# Error class for EDI Output processing.
class EdiOutError < RuntimeError; end

# Error class for EDI engine processing.
class EdiProcessError < RuntimeError; end
