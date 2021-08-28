defmodule EctoNestedChangesetTest do
  use ExUnit.Case

  import Ecto.Changeset
  import EctoNestedChangeset

  alias __MODULE__.Category
  alias __MODULE__.Comment
  alias __MODULE__.Post
  alias Ecto.Changeset

  defmodule Category do
    use Ecto.Schema

    schema "categories" do
      has_many :posts, EctoNestedChangesetTest.Post
    end
  end

  defmodule Comment do
    use Ecto.Schema

    schema "comments" do
      belongs_to :post, EctoNestedChangesetTest.Post
    end
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :title, :string
      field :tags, {:array, :string}, default: []
      belongs_to :category, EctoNestedChangesetTest.Category
      has_many :comments, EctoNestedChangesetTest.Comment
    end
  end

  describe "append_at/3" do
    test "appends item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> append_at(:posts, %Post{title: "first"})
        |> append_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}}
               ]
             } = changeset.changes
    end

    test "appends item at a root level field with existing data" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "existing"}]}
        |> change()
        |> append_at(:posts, %Post{title: "first"})
        |> append_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing"}
                 },
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}}
               ]
             } = changeset.changes
    end

    test "appends item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: []
            }
          ]
        }
        |> change()
        |> append_at([:posts, 1, :comments], %Comment{})
        |> append_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "appends item to an array field" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "first", tags: ["one"]}]}
        |> change()
        |> append_at([:posts, 0, :tags], "two")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "two"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "prepend_at/3" do
    test "prepend item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> prepend_at(:posts, %Post{title: "first"})
        |> prepend_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}}
               ]
             } = changeset.changes
    end

    test "prepend item at a root level field with existing data" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "existing"}]}
        |> change()
        |> prepend_at(:posts, %Post{title: "first"})
        |> prepend_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing"}
                 }
               ]
             } = changeset.changes
    end

    test "prepend item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: []
            }
          ]
        }
        |> change()
        |> prepend_at([:posts, 1, :comments], %Comment{})
        |> prepend_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "prepends item to an array field" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "first", tags: ["one"]}]}
        |> change()
        |> prepend_at([:posts, 0, :tags], "two")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["two", "one"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "insert_at/3" do
    test "inserts item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> insert_at([:posts, 0], %Post{title: "first"})
        |> insert_at([:posts, 0], %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "second"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "first"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "inserts item at a root level field with existing data" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "existing 1"},
            %Post{id: 2, title: "existing 2"},
            %Post{id: 3, title: "existing 3"}
          ]
        }
        |> change()
        |> insert_at([:posts, 2], %Post{title: "first"})
        |> insert_at([:posts, 1], %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 1"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "second"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 2"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "first"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 3"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "inserts item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}, %Comment{id: 2}, %Comment{id: 3}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: [%Comment{id: 4}, %Comment{id: 5}]
            }
          ]
        }
        |> change()
        |> insert_at([:posts, 0, :comments, 3], %Comment{})
        |> insert_at([:posts, 1, :comments, 1], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{action: :update, data: %Comment{}},
                       %Ecto.Changeset{action: :insert, data: %Comment{}},
                       %Ecto.Changeset{action: :update, data: %Comment{}}
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "inserts item into array field" do
      changeset =
        %Category{id: 1, posts: [%Post{title: "first", tags: ["one", "two"]}]}
        |> change()
        |> insert_at([:posts, 0, :tags, 1], "three")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "three", "two"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "delete_at/3" do
    test "deletes item from changes that isn't persisted yet" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"}
          ]
        }
        |> change()
        |> append_at([:posts], %Post{title: "three"})
        |> delete_at([:posts, 2])

      assert changeset.changes == %{}
    end

    test "deletes existing item" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"},
            %Post{id: 3, title: "three"}
          ]
        }
        |> change()
        |> delete_at([:posts, 1])

      assert %{
               posts: [
                 %Changeset{action: :update, data: %Post{id: 1}},
                 %Changeset{action: :delete, data: %Post{id: 2}},
                 %Changeset{action: :update, data: %Post{id: 3}}
               ]
             } = changeset.changes
    end

    test "deletes item from changes in nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{
              id: 2,
              title: "two",
              comments: [%Comment{id: 1}, %Comment{id: 2}]
            }
          ]
        }
        |> change()
        |> append_at([:posts, 1, :comments], %Comment{})
        |> delete_at([:posts, 1, :comments, 2])

      assert changeset.changes == %{}
    end

    test "deletes existing item from a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}, %Comment{id: 2}, %Comment{id: 3}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: [%Comment{id: 4}, %Comment{id: 5}]
            }
          ]
        }
        |> change()
        |> delete_at([:posts, 1, :comments, 0])
        |> delete_at([:posts, 0, :comments, 1])

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 1},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :delete,
                         data: %Comment{id: 2},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 3},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :delete,
                         data: %Comment{id: 4}
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 5}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "deletes item from an array field" do
      changeset =
        %Category{
          id: 1,
          posts: [%Post{title: "first", tags: ["one", "two", "three"]}]
        }
        |> change()
        |> delete_at([:posts, 0, :tags, 1])

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "three"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end
end
