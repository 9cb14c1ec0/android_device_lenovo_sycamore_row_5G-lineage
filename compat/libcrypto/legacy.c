// Android 13 BoringSSL exported sk_dup; it is now only OPENSSL_sk_dup.
typedef struct stack_st OPENSSL_STACK;

OPENSSL_STACK* OPENSSL_sk_dup(const OPENSSL_STACK* sk);

OPENSSL_STACK* sk_dup(const OPENSSL_STACK* sk) {
    return OPENSSL_sk_dup(sk);
}
