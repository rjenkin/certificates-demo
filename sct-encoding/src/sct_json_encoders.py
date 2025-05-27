import json

class SCTJSONEncoder(json.JSONEncoder):
    """
    A minimal JSON encoder that preserves object structure.
    Only handles special data types (like bytes) that JSON can't natively serialize.
    """
    def default(self, obj):
        # If the object has a __dict__, use that directly
        if hasattr(obj, '__dict__'):
            return obj.__dict__

        # Let the default encoder handle everything else
        return super().default(obj)
