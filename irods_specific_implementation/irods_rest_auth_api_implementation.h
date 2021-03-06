
#include "irods_rest_api_base.h"

// this is contractually tied directly to the swagger api definition, and the below implementation
#define MACRO_IRODS_AUTH_API_IMPLEMENTATION \
    Pistache::Http::Code code; \
    std::string message; \
    std::tie(code, message) = irods_auth_(userName.get(), password.get(), authType.get()); \
    response.send(code, message);

namespace irods {
namespace rest {
class auth : api_base {
    public:
    std::tuple<Pistache::Http::Code &&, std::string> operator()(
        const std::string& _user_name,
        const std::string& _password,
        const std::string& _auth_type ) {
        auto conn = get_connection();

        std::string jwt;
        try {
            // use the zone key as our secret
            std::string zone_key{irods::get_server_property<const std::string>(irods::CFG_ZONE_KEY_KW)};

            // pass the user name via the connection, used by client login
            rstrcpy(
                conn()->clientUser.userName,
                _user_name.c_str(),
                NAME_LEN);

            // set password in context string for auth
            kvp_map_t kvp;
            kvp[ irods::AUTH_PASSWORD_KEY] = _password;

            std::string context = irods::escaped_kvp_string(kvp);
            int err = clientLogin(
                          conn(),
                          context.c_str(),
                          _auth_type.c_str());
            if(err < 0) {
                THROW(err,
                    boost::format("[%s] failed to login with type [%s]")
                    % _user_name
                    % _auth_type);
            }

            auto token = jwt::create()
                             .set_type("JWS")
                             .set_issuer(ISSUE_CLAIM)
                             .set_subject(SUBJECT_CLAIM)
                             .set_audience(AUDIENCE_CLAIM)
                             .set_not_before(std::chrono::system_clock::now())
                             .set_issued_at(std::chrono::system_clock::now())
                             // TODO: consider how to handle token revocation, token refresh
                             //.set_expires_at(std::chrono::system_clock::now() - std::chrono::seconds{30})
                             .set_payload_claim(USER_NAME_KW, jwt::claim(std::string{_user_name}))
                             .sign(jwt::algorithm::hs256{zone_key});

            return std::forward_as_tuple(
                       Pistache::Http::Code::Ok,
                       token);
        }
        catch(const irods::exception& _e) {
            return std::forward_as_tuple(
                       Pistache::Http::Code::Bad_Request, _e.what());
        }

        return std::forward_as_tuple(
                   Pistache::Http::Code::Ok,
                   jwt);

    } // operator()
}; // class auth
}; // namespace rest
}; // namespace irods
