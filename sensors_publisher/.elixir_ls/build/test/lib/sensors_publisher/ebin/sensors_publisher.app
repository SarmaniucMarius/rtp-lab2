{application,sensors_publisher,
             [{applications,[kernel,stdlib,elixir,logger,poison,
                             eventsource_ex]},
              {description,"sensors_publisher"},
              {modules,['Elixir.Fetcher','Elixir.Main','Elixir.Scheduler',
                        'Elixir.Sensors_Processor',
                        'Elixir.WorkersSupervisor']},
              {registered,[]},
              {vsn,"0.1.0"},
              {mod,{'Elixir.Main',[0,0]}}]}.
