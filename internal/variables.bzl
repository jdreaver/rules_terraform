load("@bazel_skylib//rules:write_file.bzl", "write_file")

def terraform_locals(name, variables, **kwargs):
    """Generate a .tf.json file with the given variables as locals.

    Args:
        name: Rule name
        variables: dict from variable name to value
    """

    locals = struct(
        locals = variables
    )

    write_file(
        name = name,
        out = name + "_locals.tf.json",
        content = [json.encode_indent(locals, indent = '  ')],
        **kwargs,
    )
