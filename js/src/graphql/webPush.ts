import gql from "graphql-tag";

export const REGISTER_PUSH_MUTATION = gql`
  mutation RegisterPush($endpoint: String!, $keys: PushSubscriptionKeys!) {
    registerPush(endpoint: $endpoint, keys: $keys) {
      status
    }
  }
`;
