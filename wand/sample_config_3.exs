use Mahou.Config

[
  %App{
    name: "test",
    image: "nginxdemos/hello",
    limits: %Limits{
      cpu: 1,
      ram: 16,
    },
    inner_port: 80,
    scale: 1,
    outer_port: 5555,
    domain: "localhost:5555",
    path: "/",
  },
  %App{
    name: "test-route",
    image: "nginxdemos/hello",
    limits: %Limits{
      cpu: 1,
      ram: 16,
    },
    inner_port: 80,
    scale: 1,
    outer_port: 5555,
    domain: "test",
    path: "/",
  },
]
