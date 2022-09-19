local utils = require("py_lsp.utils")

describe("Testing all utilies", function ()

  it("Get virtualenv name from path", function ()
    local venv_name = utils.get_python_venv_name("venv/bin/python")
    assert.are.same(venv_name, "venv")
  end)


  it("Split a string", function ()
    local splitted_string = utils.split_string("hello:world", ":")
    assert.equals(splitted_string, {"hello", "world"})
  end)
  
end)
