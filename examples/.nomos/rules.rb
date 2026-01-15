# frozen_string_literal: true

rule "no_debugger" do
  changed_files.grep(/\.rb$/).each do |file|
    if diff(file).include?("binding.pry")
      fail "binding.pry detected", file: file
    end
  end
end
