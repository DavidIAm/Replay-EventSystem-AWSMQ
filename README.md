# Replay-EventSystem-AWSMQ
Amazon Web Services MQ event support for the Replay framework

We need fast and smooth event transfer for Replay to operate meaningfully.

# Capabilities Provided

## Replay::EventSystem::AWSMQ

this is the portion of the configuration of Replay that chooses to use the 
AWS MQ event system and defines the parameters used for connecting to it.  
Use the AWSMQ mode of the EventSystem and this package will be utilized.  
Include the information about what is needed to connect to your AWS
instance inside the structure

```perl
  Replay->new (
        EventSystem => {
            Mode     => 'AWSMQ',
            mqEndpoint   => 'STOMP ENDPOINT URI OF YOUR MQ SERVICE',
            mqUsername   => 'Username for your MQ SERVICE',
            mqPassword   => 'Password for your MQ SERVICE',
        },
  );
```


