module Twitter
  class NullObject
    def as_json(*)
      'null'
    end

    def to_json(*)
      'null'
    end
  end
end
